#include "lrp/TempoAction.h"
#include "lrp/ReaperApi.h"
#include <algorithm>
#include <cmath>
#include <string>
#include <sstream>
#include <iomanip>
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
    mapMode_=false;
    mapStream_=tempo_map::Stream{};
}
void TempoAction::start() { startInternal(false); }
void TempoAction::startMap() { startInternal(true); }
void TempoAction::startInternal(bool tempoMap) {
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
    mapMode_=tempoMap;
    previousTimebase_=originalMode;
    previousAutoStretch_=originalStretch;
    timebaseTemporary_=true;
    auto* accessor=CreateTakeAudioAccessor(take);
    if(!accessor){stop();speak_("Cannot read selected audio");return;}
    accessor_=accessor;
    // Tempo-map mode must inspect the entire audio, not three excerpts.
    // The streaming flux buffer stores only a compact onset envelope.
    if (mapMode_) {
        segments_.push_back({pos,duration});
        return;
    }
    // For fixed tempo, use three excerpts. At most 54 seconds decoded.
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
    if (mapMode_) { finishMap(); return; }
    auto r=tempo::analyze(mono_);
    if(r.valid) {
        // Refine coarse 0.1 BPM correlations with sub-frame beat positions.
        // This also provides true decimal BPM values instead of rounding.
        tempo_map::Stream refined;
        refined.feed(mono_.data(),mono_.size());
        auto envelope=refined.envelope();
        auto measured=tempo_map::analyze(envelope,r.bpm);
        if(measured.valid && !measured.varying &&
           std::abs(measured.bpm-r.bpm)<2.5 && measured.confidence>0.40)
            r.bpm=measured.bpm;
        estimates_.push_back(r);
    }
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
    const double bpm=std::clamp(bpmResult.bpm,55.0,210.0);
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
    std::ostringstream msg;
    msg<<std::fixed<<std::setprecision(3)<<bpm<<" BPM";
    speak_(msg.str());
}
void TempoAction::finishMap() {
    if (!CountTempoTimeSigMarkers || !SetTempoTimeSigMarker ||
        !GetTempoTimeSigMarker || !Undo_BeginBlock2 || !Undo_EndBlock2 ||
        !Undo_DoUndo2 || !SetMediaItemTakeInfo_Value) {
        stop(); speak_("Tempo map unavailable"); return;
    }
    // Do not modify an existing tempo map, even if analysis succeeds.
    // The user can deliberately work from a clean tempo map instead.
    const int existingTempoCount=CountTempoTimeSigMarkers(project_);
    if(existingTempoCount>1) {
        stop(); speak_("Existing tempo map. BPM unchanged"); return;
    }
    if(existingTempoCount==1) {
        double existingPosition=0.0;
        if(!GetTempoTimeSigMarker(project_,0,&existingPosition,nullptr,nullptr,
             nullptr,nullptr,nullptr,nullptr) || std::abs(existingPosition)>0.001) {
            stop();speak_("Existing tempo map. BPM unchanged");return;
        }
    }
    auto envelope=mapStream_.envelope();
    const double guide=tempo_map::initialTempo(envelope);
    auto result=tempo_map::analyze(envelope,guide);
    if(!result.valid || result.confidence<0.47 ||
       result.points.empty() || result.points.size()>500) {
        stop(); speak_("Tempo map not reliable"); return;
    }
    auto* project=project_;
    auto* item=item_;
    auto* take=take_;
    if(project!=EnumProjects(-1,nullptr,0) ||
       CountSelectedMediaItems(project)!=1 ||
       GetSelectedMediaItem(project,0)!=item ||
       !ValidatePtr2(project,item,"MediaItem*") ||
       !ValidatePtr2(project,take,"MediaItem_Take*")) {
        stop(); speak_("Project changed. Tempo map unchanged"); return;
    }
    const double position=GetMediaItemInfo_Value(item,"D_POSITION");
    const double length=GetMediaItemInfo_Value(item,"D_LENGTH");
    const double rate=GetMediaItemTakeInfo_Value(take,"D_PLAYRATE");
    if(!std::isfinite(position)||!std::isfinite(length)||!std::isfinite(rate)||rate<=0) {
        stop(); speak_("Tempo map unchanged"); return;
    }
    // Tempo anchors are written directly, without MIDI notes/project markers.
    // The prelude is adjusted to bring the first musical pulse onto an
    // integer beat. This can only approximate true musical downbeats.
    double lead=result.beats.front();
    double introBpm=result.points.front().bpm;
    if(lead>0.20 && lead<16.0) {
        const int whole=std::max(1,int(std::round(lead*introBpm/60.0)));
        const double computed=60.0*whole/lead;
        if(computed>=45 && computed<=240)introBpm=computed;
    }
    if(accessor_) DestroyAudioAccessor(accessor_);
    accessor_=nullptr;
    Undo_BeginBlock2(project);
    // Update the initial marker rather than create a duplicate at 0 seconds.
    double initialAt=0.0;
    const bool haveInitial=CountTempoTimeSigMarkers(project)==1 &&
        GetTempoTimeSigMarker(project,0,&initialAt,nullptr,nullptr,nullptr,nullptr,nullptr,nullptr);
    const int firstIndex=(haveInitial && std::abs(initialAt-position)<1e-5)?0:-1;
    bool okay=SetTempoTimeSigMarker(project,firstIndex,position,-1,-1,introBpm,0,0,false);
    double last=position;
    std::size_t inserted=0;
    // Tempo changes are anchored in project seconds; never coalesce
    // separate events after creating them, or their timing can drift.
    for(auto marker:result.points) {
        double t=position+marker.seconds;
        if(!okay)break;
        if(t<=last+0.03)continue;
        if(!std::isfinite(t)||!std::isfinite(marker.bpm)||marker.bpm<45||marker.bpm>240){okay=false;break;}
        okay=SetTempoTimeSigMarker(project,-1,t,-1,-1,marker.bpm,0,0,false);
        // In projects with beat-anchored tempo markers, REAPER may adjust
        // requested seconds. Never accept a silently shifted tempo map.
        if(okay) {
            double actual=0.0;
            const int index=CountTempoTimeSigMarkers(project)-1;
            okay=index>=0 && GetTempoTimeSigMarker(project,index,&actual,
                nullptr,nullptr,nullptr,nullptr,nullptr,nullptr) &&
                std::abs(actual-t)<0.012;
        }
        if(okay)++inserted;
        last=t;
    }
    restoreTimebase();
    SetMediaItemInfo_Value(item,"D_POSITION",position);
    SetMediaItemInfo_Value(item,"D_LENGTH",length);
    SetMediaItemTakeInfo_Value(take,"D_PLAYRATE",rate);
    Undo_EndBlock2(project,"LReaParams: tempo map from selected audio",UNDO_STATE_ALL);
    if(!okay) {
        Undo_DoUndo2(project);
        stop(); speak_("Tempo map unchanged");return;
    }
    auto count=inserted+std::size_t(firstIndex<0?1:0);
    double bpm=result.bpm;
    stop();
    if(UpdateArrange)UpdateArrange();
    std::ostringstream msg;
    msg<<std::fixed<<std::setprecision(3)<<bpm<<" BPM. "
       <<(result.varying?"Tempo map":"Fixed tempo")
       <<". "<<count<<" tempo markers";
    speak_(msg.str());
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
    if(mapMode_) {
        std::vector<float> buffer(count);
        for(std::size_t i=0;i<count;++i)
            buffer[i]=float(std::clamp((interleaved[2*i]+interleaved[2*i+1])*0.5,-1.0,1.0));
        mapStream_.feed(buffer.data(),buffer.size());
    } else {
        for(std::size_t i=0;i<count;++i)
            mono_.push_back(float(std::clamp((interleaved[2*i]+interleaved[2*i+1])*0.5,-1.0,1.0)));
    }
    frame_+=count;
    if(frame_>=frames) nextSegment();
}
}
