#include "lrp/TempoAction.h"
#include "lrp/ReaperApi.h"
#include <algorithm>
#include <cmath>
#include <string>
#include <vector>

namespace lrp {
TempoAction::~TempoAction() { stop(); }
void TempoAction::restoreTimebase() {
    if (!timebaseTemporary_) return;
    // Restore even if the user switched projects, provided this item is alive.
    // Never dereference an item until REAPER validates it in its original project.
    if (project_ && item_ && ValidatePtr2 &&
        ValidatePtr2(project_, item_, "MediaItem*") && SetMediaItemInfo_Value) {
        SetMediaItemInfo_Value(item_, "C_BEATATTACHMODE", previousTimebase_);
        SetMediaItemInfo_Value(item_, "C_AUTOSTRETCH", previousAutoStretch_);
        if (UpdateArrange) UpdateArrange();
    }
    timebaseTemporary_ = false;
}
void TempoAction::stop() {
    restoreTimebase();
    if(accessor_) DestroyAudioAccessor(accessor_);
    accessor_=nullptr;
    project_=nullptr;
    item_=nullptr;
    take_=nullptr;
    segments_.clear();
    estimates_.clear();
    mono_.clear();
    frame_=segment_=0;
}
void TempoAction::start() {
    stop();
    auto* project = EnumProjects(-1,nullptr,0);
    if(!project || CountSelectedMediaItems(project)!=1) {
        speak_("Select one audio item");
        return;
    }
    auto* item = GetSelectedMediaItem(project,0);
    auto* take = item ? GetActiveTake(item) : nullptr;
    if (!take || TakeIsMIDI(take)) { speak_("Select one audio item"); return; }
    const double pos=GetMediaItemInfo_Value(item,"D_POSITION");
    const double duration=GetMediaItemInfo_Value(item,"D_LENGTH");
    if(!std::isfinite(pos)||!std::isfinite(duration)||duration<7.0) {
        speak_("Audio too short for reliable BPM detection");
        return;
    }
    // Preserve the exact original timebase (including inherited -1) and
    // auto-stretch before analysis. This protection is temporary, not a
    // permanent change to the user's item preferences.
    if (!GetMediaItemInfo_Value || !SetMediaItemInfo_Value || !ValidatePtr2) {
        speak_("Cannot protect audio timebase"); return;
    }
    const double originalMode=GetMediaItemInfo_Value(item,"C_BEATATTACHMODE");
    const double originalStretch=GetMediaItemInfo_Value(item,"C_AUTOSTRETCH");
    if (!SetMediaItemInfo_Value(item,"C_BEATATTACHMODE",0.0) ||
        !SetMediaItemInfo_Value(item,"C_AUTOSTRETCH",0.0)) {
        SetMediaItemInfo_Value(item,"C_BEATATTACHMODE",originalMode);
        SetMediaItemInfo_Value(item,"C_AUTOSTRETCH",originalStretch);
        speak_("Cannot protect audio timebase"); return;
    }
    project_=project; item_=item; take_=take;
    previousTimebase_=originalMode;
    previousAutoStretch_=originalStretch;
    timebaseTemporary_=true;
    auto* accessor=CreateTakeAudioAccessor(take);
    if(!accessor){stop();speak_("Cannot read selected audio");return;}
    accessor_=accessor;
    // For songs, use three separated excerpts to avoid trusting only the
    // intro or an isolated fill. At most 54 seconds decoded in total.
    const double window=std::min(18.0,duration);
    auto add=[&](double fraction){
        const double start=pos+std::max(0.0,(duration-window)*fraction);
        if (segments_.empty() || std::abs(segments_.back().start-start)>2.0)
            segments_.push_back({start,window});
    };
    if(duration<=24) add(0.0);
    else if(duration<=42){ add(0.05);add(0.80); }
    else {add(0.12);add(0.45);add(0.80);}
    mono_.reserve(std::size_t(window*tempo::sampleRate)+1);
}
void TempoAction::nextSegment() {
    auto r=tempo::analyze(mono_);
    if(r.valid) estimates_.push_back(r);
    mono_.clear();
    frame_=0;
    ++segment_;
    if(segment_>=segments_.size()) finish();
}
void TempoAction::finish() {
    // For long songs require two independent excerpts to agree; never
    // accept one isolated rhythmic passage as the entire song tempo.
    if(segments_.size()>1 && estimates_.size()<2) {
        stop();
        speak_("BPM not reliable");
        return;
    }
    const auto bpmResult=tempo::combine(estimates_);
    if(!bpmResult.valid || !std::isfinite(bpmResult.bpm)) {
        stop();
        speak_("BPM not reliable");
        return;
    }
    const int bpm=std::clamp(int(std::lround(bpmResult.bpm)),55,210);
    ReaProject* project=project_;
    MediaItem* originalItem=item_;
    MediaItem_Take* originalTake=take_;
    if(project != EnumProjects(-1,nullptr,0) ||
       CountSelectedMediaItems(project)!=1 ||
       GetSelectedMediaItem(project,0)!=originalItem ||
       !ValidatePtr2(project,originalItem,"MediaItem*") ||
       !ValidatePtr2(project,originalTake,"MediaItem_Take*")) {
        stop();
        speak_("Project changed. BPM unchanged");
        return;
    }
    // Preserve the physical audio properties. Restoring Beats must not undo
    // the protection against stretching caused by the tempo change.
    const double position=GetMediaItemInfo_Value(originalItem,"D_POSITION");
    const double length=GetMediaItemInfo_Value(originalItem,"D_LENGTH");
    const double playRate=GetMediaItemTakeInfo_Value(originalTake,"D_PLAYRATE");
    if (!Undo_BeginBlock2 || !Undo_EndBlock2 || !SetCurrentBPM ||
        !SetMediaItemTakeInfo_Value || !std::isfinite(position) ||
        !std::isfinite(length) || !std::isfinite(playRate) || playRate<=0) {
        stop(); speak_("BPM unchanged"); return;
    }
    // First destroy accessor but keep the temporary Time override until the
    // tempo has been changed. The *final* item state is its original timebase.
    if(accessor_) DestroyAudioAccessor(accessor_);
    accessor_=nullptr;
    Undo_BeginBlock2(project);
    SetCurrentBPM(project, double(bpm), false);
    restoreTimebase();
    SetMediaItemInfo_Value(originalItem,"D_POSITION",position);
    SetMediaItemInfo_Value(originalItem,"D_LENGTH",length);
    SetMediaItemTakeInfo_Value(originalTake,"D_PLAYRATE",playRate);
    Undo_EndBlock2(project, "LReaParams: detect BPM (restore original item timebase)",
                   UNDO_STATE_ALL);
    // No second restoration is needed when clearing the completed job.
    stop();
    if (UpdateArrange) UpdateArrange();
    speak_(std::to_string(bpm)+" BPM");
}
void TempoAction::tick() {
    if (!active()) return;
    if(project_!=EnumProjects(-1,nullptr,0) ||
        CountSelectedMediaItems(project_)!=1 ||
        GetSelectedMediaItem(project_,0)!=item_ ||
        !ValidatePtr2(project_,item_,"MediaItem*") ||
        !ValidatePtr2(project_,take_,"MediaItem_Take*") ||
        AudioAccessorStateChanged(accessor_)) {
        stop();speak_("Audio changed. BPM unchanged");return;
    }
    if(segment_>=segments_.size()){finish();return;}
    const auto& seg=segments_[segment_];
    const std::size_t frames=std::size_t(seg.duration*tempo::sampleRate);
    const std::size_t count=std::min(std::size_t(16384),frames-frame_);
    if(!count){nextSegment();return;}
    std::vector<double> interleaved(count*2,0);
    const double readPosition=seg.start + frame_/double(tempo::sampleRate);
    int result=GetAudioAccessorSamples(accessor_,tempo::sampleRate,2,
        readPosition,int(count),interleaved.data());
    if(result<0){stop();speak_("Cannot read selected audio");return;}
    for(std::size_t i=0;i<count;++i) {
        mono_.push_back(float(std::clamp((interleaved[2*i]+interleaved[2*i+1])*0.5,-1.0,1.0)));
    }
    frame_+=count;
    if(frame_>=frames) nextSegment();
}
}
