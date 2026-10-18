#include "lrp/Profile.h"
#include "lrp/Storage.h"
#include "lrp/FxOrder.h"
#include "lrp/TrackMemory.h"
#include "lrp/ReaEqVirtual.h"
#include <windows.h>
#include <fstream>
#include <iostream>
#include <map>
#include <functional>

using namespace lrp;
namespace {
void check(bool value, const char* error) { if (!value) throw std::runtime_error(error); }
void rejected(const std::function<void()>& f) { bool failed = false; try { f(); } catch (const ProfileError&) { failed = true; } check(failed, "Malformed input was accepted"); }
void overwrite(const fs::path& p, const std::string& value) {
    fs::create_directories(p.parent_path()); std::ofstream f(p, std::ios::binary | std::ios::trunc);
    f.write(value.data(), static_cast<std::streamsize>(value.size())); f.close(); check(!f.fail(), "Test write failed");
}
std::map<fs::path, fs::file_time_type> times(const fs::path& root) {
    std::map<fs::path, fs::file_time_type> result;
    for (const auto& e : fs::recursive_directory_iterator(root)) if (e.is_regular_file()) result[e.path()] = e.last_write_time();
    return result;
}
void corpus(const fs::path& root) {
    int count = 0; std::map<ProfileKind,int> counts;
    for (const auto& entry : fs::recursive_directory_iterator(root)) {
        if (!entry.is_regular_file() || entry.path().extension() != L".txt") continue;
        auto bytes = readFile(entry.path()); const auto p = parseLegacy(bytes);
        const auto native = serializeNative(p); const auto q = parseNative(native);
        check(q.payload == bytes && q.kind == p.kind, "Roundtrip changed original bytes");
        check(q.headers == p.headers && q.sections == p.sections && q.records == p.records, "Roundtrip changed parsed values");
        check(serializeNative(q) == native, "Native serialization not idempotent");
        rejected([&] { parseNative(native + "X"); });
        ++count; ++counts[p.kind];
    }
    check(count == 52 && counts[ProfileKind::fx] == 48 && counts[ProfileKind::track] == 4, "Expected all 52 fixtures");
    std::cout << "52 profiles, exact byte + semantic roundtrip passed\n";
}
}
int main(int argc, char** argv) {
    try {
        check(argc >= 2, "Need fixture root"); const auto fixtures = fs::u8path(argv[1]); corpus(fixtures);
        if (argc == 3) corpus(fs::u8path(argv[2])); // Optional private corpus supplied only by the owner.
        check(sha256("abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", "SHA256 known-answer failed");
        const auto fx = readFile(fixtures / L"Plugins" / L"fixture_001.txt");
        rejected([] { parseLegacy("Version=3\n"); });
        rejected([] { parseLegacy("Version=2\nOther=not a track file\n"); });
        rejected([] { parseLegacy(std::string("Version=3\0payload", 17)); });
        rejected([&] { auto s = fx; s.replace(s.find("Version=3"), 9, "Version=99"); parseLegacy(s); });
        rejected([] { parseLegacy("Version=2\nF4CCScope=Plugin\n[Track]\nPan=17,128\n[Sends]\n[Receives]\n[FXParams.Plugin]\n"); });
        rejected([&] { parseLegacy(fx + "\n[CustomOrder]\n"); });
        const auto future = parseLegacy(fx + "\n[Future]\nopaque-content\n");
        check(parseNative(serializeNative(future)).payload == future.payload, "Unknown section lost");
        const auto bom = parseLegacy(std::string("\xEF\xBB\xBF") + fx);
        check(parseNative(serializeNative(bom)).payload == bom.payload, "BOM lost");
        std::string crlf; for (char c : fx) { if (c == '\n') crlf += '\r'; crlf += c; }
        check(parseNative(serializeNative(parseLegacy(crlf))).payload == crlf, "CRLF lost");

        const auto root = fs::temp_directory_path() / fs::u8path("LReaParams-test-città-" + std::to_string(GetCurrentProcessId()) + "-" + std::to_string(GetTickCount64()));
        struct Cleanup { fs::path p; ~Cleanup() { std::error_code error; fs::remove_all(p, error); } } cleanup{root};
        std::atomic_bool cancel{false};
        auto report = importProfiles(root, cancel);
        check(report.errors == 0 && report.imported == 0, "Empty legacy root failed");
        const auto legacy = root / L"Scripts" / L"Lo-lo - Scripts" / L"Utility" / L"Scripts";
        for (const auto& e : fs::recursive_directory_iterator(fixtures)) if (e.is_regular_file()) {
            auto to = legacy / e.path().lexically_relative(fixtures); fs::create_directories(to.parent_path()); fs::copy_file(e.path(), to);
        }
        report = importProfiles(root, cancel);
        check(report.imported == 52 && report.errors == 0 && report.rejected == 0, "Full import failed");
        int originals = 0; for (const auto& e : fs::recursive_directory_iterator(legacy)) if (e.is_regular_file()) ++originals;
        check(originals == 52, "Legacy original removed");
        const auto before = times(root / L"LReaParams");
        report = importProfiles(root, cancel);
        check(report.unchanged == 52 && report.imported == 0 && report.errors == 0, "Repeat import failed");
        check(times(root / L"LReaParams") == before, "Idempotent import rewrote a file");
        const auto target = root / L"LReaParams" / L"Plugins" / L"fixture_001.fx";
        const auto userEdit = serializeNative(parseLegacy(fx + "\n# Native user edit\n"));
        overwrite(target, userEdit);
        report = importProfiles(root, cancel);
        check(report.unchanged == 52 && readFile(target) == userEdit, "Repeat import overwrote a user edit");
        const auto originalTarget = readFile(target);
        overwrite(legacy / L"Plugins" / L"fixture_001.txt", fx + "\n# Source changed\n");
        report = importProfiles(root, cancel);
        check(report.conflicts == 1 && readFile(target) == originalTarget, "Source conflict overwrote target");
        const auto active = root / L"LReaParams" / L"Plugins" / fs::u8path("città d'esempio") / L"new.txt";
        overwrite(active, fx); report = importProfiles(root, cancel);
        check(report.removed == 1 && !fs::exists(active), "Active TXT not removed after conversion");
        auto converted = active; converted.replace_extension(L".fx");
        check(parseNative(readFile(converted)).payload == fx, "Unicode conversion corrupt");
        check(readFile(root / L"LReaParams" / L"Backups" / fs::u8path(sha256(fx) + ".txt")) == fx, "Backup missing or corrupt");
        const auto invalid = root / L"LReaParams" / L"Plugins" / L"unknown.txt";
        overwrite(invalid, "Version=3\nNot a profile\n"); report = importProfiles(root, cancel);
        check(fs::exists(invalid) && report.rejected >= 1, "Malformed TXT was removed");
        check(!fs::exists(root / L"LReaParams" / L"Params"), "Importer created retired directory");
        const auto ignored = root / L"LReaParams" / L"Params" / L"old.pp";
        overwrite(ignored, "untouched"); report = importProfiles(root, cancel);
        check(readFile(ignored) == "untouched", "Retired data modified");
        // Roundtrip intentional profile edits, including hidden CC links and virtual Compare.
        const auto profileRoot = root / L"profile-edits";
        FxOrder order;
        order.load(profileRoot,"Synthetic edit test",4,[](int id){return id==compareParamIndex?std::string("Compare"):"Parameter "+std::to_string(id);});
        check(!order.hasRealModifications(),"Compare must not create a Custom Order");
        order.ccLinks[1]="2\t74";order.hidden.insert(1);
        order.paramSlots[12]=compareParamIndex;
        order.setExtraValue("future_key","opaque value");
        check(order.save(),"FX save failed");
        FxOrder reopened;
        reopened.load(profileRoot,"Synthetic edit test",4,[](int id){return id==compareParamIndex?std::string("Compare"):"Parameter "+std::to_string(id);});
        check(reopened.ccLinks.at(1)=="2\t74" && reopened.hidden.count(1),"Hidden MIDI association lost");
        check(reopened.paramSlots.at(12)==compareParamIndex,"Virtual memory index lost");
        check(reopened.extraValue("future_key")=="opaque value","Unknown extra lost");
        // 0.0.48: native Step overrides and the legacy Lua Step table coexist;
        // changing Ctrl+T on one parameter must not touch other preferences.
        const std::string luaSteps="1\tParameter 1\tv3:4\n3\tParameter 3\tv3:12";
        const std::string nativeSteps="1\tParameter 1\t-6\n3\tParameter 3\t0";
        reopened.setExtraValue("param_step_scales_v1",luaSteps);
        reopened.setExtraValue("lrp_param_step_scales_v1",nativeSteps);
        reopened.setExtraValue("cc_param_speech_v1::1","1");
        check(reopened.save(),"Unable to persist independent Step settings");
        FxOrder stepped;
        stepped.load(profileRoot,"Synthetic edit test",4,[](int id){return id==compareParamIndex?std::string("Compare"):"Parameter "+std::to_string(id);});
        check(stepped.extraValue("param_step_scales_v1")==luaSteps,"Legacy Lua steps were overwritten");
        check(stepped.extraValue("lrp_param_step_scales_v1")==nativeSteps,"Native parameter steps lost");
        check(stepped.extraValue("cc_param_speech_v1::1")=="1","Per-parameter CC speech lost");
        check(stepped.ccLinks.at(1)=="2\t74" && stepped.paramSlots.at(12)==compareParamIndex,
              "Step changes damaged unrelated FX profile sections");
        check(stepped.deleteCcLink(1),"Hidden CC deletion failed");
        FxOrder cleared;
        cleared.load(profileRoot,"Synthetic edit test",4,[](int id){return id==compareParamIndex?std::string("Compare"):"Parameter "+std::to_string(id);});
        check(!cleared.ccLinks.count(1),"Deleted hidden CC reappeared");
        // Real FxOrder profile migration regression: a saved 0.0.43 profile
        // may append every ReaEQ virtual after the Global Gain. Loading it
        // MUST restore the Lua per-band layout WITHOUT rewriting user data.
        const auto eqRoot = root / L"reaeq-order";
        const auto eqName = std::string("ReaEQ migration synthetic");
        const auto eqNames = [](int id) {
            if (id == compareParamIndex) return std::string("Compare");
            if (id == reaeq::target) return std::string("ReaEQ Target Band");
            if (id == reaeq::action) return std::string("ReaEQ Band Action");
            if (id < 0) return std::string("Band ") + std::to_string(reaeq::band(id)+1) +
                (reaeq::enabledId(id)?" Enabled":" Type");
            return std::string("Parameter ")+std::to_string(id);
        };
        const auto eqNative = reaeq::pluginOrder(2,9,compareParamIndex);
        FxOrder oldEq;
        oldEq.load(eqRoot,eqName,9,eqNames,eqNative);
        oldEq.custom=true;
        oldEq.order={0,1,2,4,3,5,compareParamIndex,6,7,8};
        check(oldEq.save(),"Cannot prepare old ReaEQ Custom Order profile");
        const auto eqFiles = eqRoot / L"LReaParams" / L"Plugins";
        auto item=fs::directory_iterator(eqFiles);
        check(item!=fs::directory_iterator(),"ReaEQ fixture was not saved");
        const auto eqPath=item->path();
        const auto storedEq=readFile(eqPath);
        FxOrder migratedEq;
        migratedEq.load(eqRoot,eqName,9,eqNames,eqNative);
        const std::vector<int> intended{
            reaeq::enabled(0),reaeq::type(0),0,1,2,
            reaeq::enabled(1),reaeq::type(1),4,3,5,
            reaeq::target,reaeq::action,compareParamIndex,6,7,8};
        check(migratedEq.visibleOrder()==intended,"ReaEQ virtuals still follow Global Gain");
        check(readFile(eqPath)==storedEq,"Passive ReaEQ order migration rewrote .fx profile");
        // Lua-compatible LastParam survives REAPER restart without changing
        // user CustomOrder, hidden params, groups, MIDI or arbitrary extras.
        const auto posRoot = root / L"persistent-position";
        const auto posNames = [](int id) {
            return id == compareParamIndex ? std::string("Compare") :
                std::string("Parameter ") + std::to_string(id);
        };
        FxOrder positionProfile;
        positionProfile.load(posRoot, "Position test", 6, posNames);
        positionProfile.ccLinks[2] = "1,74";
        positionProfile.groupNames[1] = "Kick";
        positionProfile.setExtraValue("unknown_future", "leave\nuntouched");
        check(positionProfile.save(), "Cannot create position fixture");
        const auto posDirectory = posRoot / L"LReaParams" / L"Plugins";
        const auto posFile = fs::directory_iterator(posDirectory)->path();
        const auto beforePosition = parseNative(readFile(posFile)).payload;
        check(positionProfile.persistLastParameter(4,"Parameter 4"), "Cannot persist LastParam");
        const auto afterPosition = parseNative(readFile(posFile)).payload;
        std::string expected = beforePosition;
        const auto oldField = expected.find("LastParam=");
        check(oldField != std::string::npos,"Missing LastParam test field");
        const auto afterField = expected.find('\n', oldField);
        check(afterField != std::string::npos,"Missing field boundary");
        expected.replace(oldField, afterField-oldField, "LastParam=4\tParameter 4");
        check(afterPosition == expected,"LastParam update changed an unrelated profile byte");
        FxOrder nextSession;
        nextSession.load(posRoot, "Position test", 6, posNames);
        check(nextSession.lastParameterRecord() == "4\tParameter 4", "LastParam not restored after restart");
        check(nextSession.ccLinks.at(2) == "1,74" && nextSession.groupNames.at(1) == "Kick" &&
              nextSession.extraValue("unknown_future") == "leave\nuntouched",
              "Position update damaged CC, groups or future fields");
        check(nextSession.persistLastParameter(1,"Parameter 1"), "Cannot update a saved position");
        FxOrder laterSession;
        laterSession.load(posRoot,"Position test",6,posNames);
        check(laterSession.lastParameterRecord()=="1\tParameter 1", "Recent LastParam lost");
        const auto diskBeforeConflict = readFile(posFile);
        // An external writer wins: never silently overwrite a newer profile.
        FxOrder stale;
        stale.load(posRoot,"Position test",6,posNames);
        laterSession.persistLastParameter(2,"Parameter 2");
        const auto externalBytes=readFile(posFile);
        rejected([&] {stale.persistLastParameter(3,"Parameter 3");});
        check(readFile(posFile)==externalBytes && diskBeforeConflict!=externalBytes,
              "Stale LastParam save overwrote an external change");
        const auto backupRoot=posRoot/L"LReaParams"/L"Backups"/L"ProfileEdits";
        check(fs::exists(backupRoot) && !fs::is_empty(backupRoot),"LastParam backups missing");
        // 0.0.47: F7/F8 profile persistence with virtual dynamics, duplicate
        // Custom Order occurrences, named groups, all twelve slot indices
        // and CC metadata. The native test runs only in GitHub Actions.
        const auto f7Root = root / L"f7-f8-profile";
        const auto f7Names = [](int id) {
            if (id == compareParamIndex) return std::string("Compare");
            if (id == -200000) return std::string("Detector filter range");
            return std::string("Parameter ")+std::to_string(id);
        };
        const std::vector<int> f7Native{0,1,-200000,2,compareParamIndex,3};
        FxOrder f7;
        f7.load(f7Root,"F7 F8 dynamics fixture",4,f7Names,f7Native);
        check(f7.createCustomOrder(),"Cannot create F7 fixture order");
        f7.custom=true;
        f7.order={0,1,-200000,-200000,2,compareParamIndex,3};
        f7.aliases[1]="Custom threshold";
        f7.hidden.insert(-200000);
        f7.groups[12]={-200000,1,-200000};
        f7.groupNames[12]="Dynamics";
        f7.paramSlots[12]=-200000;
        f7.ccLinks[1]="2\t74";
        f7.groupSlotMode=true;
        check(f7.save(),"Cannot save F7 F8 fixture");
        FxOrder f8;
        f8.load(f7Root,"F7 F8 dynamics fixture",4,f7Names,f7Native);
        check(f8.storedCustomOrder() && f8.custom,"Custom Order not restored");
        check(f8.order==f7.order,"Duplicated virtual occurrence lost");
        check(f8.hidden.count(-200000),"Hidden virtual control lost");
        check(f8.aliases.at(1)=="Custom threshold","Custom alias lost");
        check(f8.groups.at(12)==f7.groups.at(12) && f8.groupNames.at(12)=="Dynamics",
              "Named Group 12 and its duplicates not restored");
        check(f8.paramSlots.at(12)==-200000 && f8.groupSlotMode,
              "Memory position 12 or Groups mode lost");
        check(f8.ccLinks.at(1)=="2\t74","MIDI CC mapping lost");
        check(f8.visibleOrder()==std::vector<int>({0,1,2,compareParamIndex,3}),
              "Hidden virtuals leaked into visible Custom Order");
        // 0.0.54.1: all Track Params preferences, mappings and future F4
        // share ONE project .tp; the previous global map is only a seed.
        const auto trackRoot = root / L"track-memory54-project";
        const auto globalTrackFile = trackRoot / L"LReaParams" / L"Tracks" / L"Track CC Map.tp";
        const std::string oldTrackPayload =
            "# historical Track CC map\r\nVersion=2\r\nF4CCScope=ProjectTrack\r\n"
            "[Track]\r\nVolume=1,7\r\nPan=2,10\r\n"
            "[Sends]\r\nVolume=3,11\r\n[Receives]\r\n"
            "[FXParams.Plugin]\r\nSynthetic|1:Parameter=1,25\r\n"
            "[CCSpeech.Track]\r\nVolume=1\r\n"
            "[UnknownFuture]\r\nopaque data\r\n";
        const auto oldGlobalBytes = serializeNative(parseLegacy(oldTrackPayload));
        overwrite(globalTrackFile, oldGlobalBytes);
        const std::string savedProject = "C:\\Music\\Album\\Bass.rpp";
        TrackMemory tm;
        tm.load(trackRoot, savedProject);
        check(!tm.fixedEnabled() && tm.ccLink("Track", "Volume") == "1,7",
            "Legacy type-wide CC should remain readable but inactive without a GUID");
        check(tm.step("Track.Volume") == 0 && tm.ccSpeech("Track", "Volume"),
            "Imported memory preferences wrong");
        const auto projectTp = tm.file();
        check(projectTp != globalTrackFile && projectTp.extension() == L".tp" &&
            projectTp.parent_path().filename() == L"Bass", "Expected project-specific .tp path");
        tm.setStep("Track.Volume", -4);
        tm.setStep("Track.Pan", 2);
        tm.setStep("Sends.Volume", -3);
        tm.setValueSpeech("Track.Pan", false);
        tm.setCcSpeech("Track", "Volume", false);
        tm.setCcSpeech("Sends", "Pan", true);
        tm.setPosition("F1.Parameter", "Track.Pan");
        tm.setCcLink("Track", "Volume", "4,77");
        tm.setFixedEnabled(true);
        tm.setVolumeRange("Track", -60.0, 12.0);
        check(tm.volumeRange("Track").first == -60.0 && tm.volumeRange("Track").second == 12.0,
              "Track volume range not set before flush");
        const std::string trackSlotGuid = "{12345678-1234-1234-1234-1234567890AB}";
        check(tm.trackSlot(2).empty() && tm.entries("LReaParams.TrackPositions").empty(),
              "Track slots should start empty");
        tm.setTrackSlot(2, trackSlotGuid);
        // TEST55.3: Fixed CC identities belong to a GUID, not the generic Pan
        // control. Two tracks may have different controllers for the same Pan.
        const std::string otherGuid = "{A2345678-1234-1234-1234-1234567890AB}";
        const std::string bassPan = "Track|" + trackSlotGuid + "|Pan";
        const std::string drumsPan = "Track|" + otherGuid + "|Pan";
        const std::string firstSend = "Sends|" + trackSlotGuid + "|" + otherGuid + "|1|Volume";
        const std::string secondSend = "Sends|" + trackSlotGuid + "|" + otherGuid + "|2|Volume";
        tm.setFixedCcLink(bassPan, "1,10");
        tm.setFixedCcLink(drumsPan, "1,11");
        tm.setFixedCcLink(firstSend, "2,14");
        tm.setFixedCcLink(secondSend, "2,15");
        check(tm.fixedCcLinks().size() == 4 && tm.fixedCcLink(bassPan) == "1,10" &&
              tm.fixedCcLink(drumsPan) == "1,11" && tm.fixedCcLink(secondSend) == "2,15",
              "Scoped CC identities collapsed two tracks or duplicate sends");
        rejected([&] { tm.setFixedCcLink("Pan", "1,10"); });
        check(tm.trackSlot(2) == trackSlotGuid &&
              tm.entries("LReaParams.TrackPositions").at("Slot2") == trackSlotGuid,
              "Track position not visible before flush");
        tm.flush();
        check(readFile(globalTrackFile) == oldGlobalBytes,
            "Project profile accidentally modified the general legacy mapping");
        const auto trackEdited = parseNative(readFile(projectTp)).payload;
        check(trackEdited.find("[Track]\r\nVolume=4,77\r\nPan=2,10\r\n") != std::string::npos &&
              trackEdited.find("[Sends]\r\nVolume=3,11\r\n") != std::string::npos &&
              trackEdited.find("[UnknownFuture]\r\nopaque data\r\n") != std::string::npos &&
              trackEdited.find("[CCSpeech.Track]\r\nVolume=\r\n") != std::string::npos &&
              trackEdited.find("[LReaParams.StepScales]\r\n") != std::string::npos &&
              trackEdited.find("[FXParams.ProjectTrack]") != std::string::npos,
              "Track project profile lost formatting, CC, F4 namespace or old sections");
        TrackMemory tmAgain;
        tmAgain.load(trackRoot, savedProject);
        check(tmAgain.volumeRange("Track").first == -60.0 && tmAgain.volumeRange("Track").second == 12.0,
              "Project volume range not persisted");
        check(tmAgain.trackSlot(2) == trackSlotGuid &&
              tmAgain.entries("LReaParams.TrackPositions").at("Slot2") == trackSlotGuid,
              "Track position not persisted in project TP");
        check(tmAgain.fixedCcLink(bassPan) == "1,10" &&
              tmAgain.fixedCcLink(drumsPan) == "1,11" &&
              tmAgain.fixedCcLink(firstSend) == "2,14" &&
              tmAgain.fixedCcLink(secondSend) == "2,15" &&
              tmAgain.fixedCcLinks().size() == 4,
              "Project-scoped Fixed CC identities did not persist");
        tmAgain.setFixedCcLink(bassPan, ""); tmAgain.flush();
        TrackMemory afterScopedDelete;
        afterScopedDelete.load(trackRoot, savedProject);
        check(afterScopedDelete.fixedCcLink(bassPan).empty() &&
              afterScopedDelete.fixedCcLink(drumsPan) == "1,11" &&
              afterScopedDelete.fixedCcLink(secondSend) == "2,15",
              "Deleting one Fixed CC erased a different track or duplicated send");
        check(tmAgain.fixedEnabled() && tmAgain.ccLink("Track", "Volume") == "4,77" &&
            tmAgain.step("Track.Volume") == -4 && tmAgain.step("Track.Pan") == 2 &&
            tmAgain.step("Sends.Volume") == -3, "Project Fixed CC or Steps not restored");
        check(!tmAgain.valueSpeech("Track.Pan") && tmAgain.valueSpeech("Track.Volume") &&
              !tmAgain.ccSpeech("Track", "Volume") && tmAgain.ccSpeech("Sends", "Pan") &&
              tmAgain.position("F1.Parameter") == "Track.Pan",
              "Speech or navigation was not restored from the project .tp");
        tmAgain.setFixedEnabled(false); tmAgain.flush();
        tmAgain.setTrackSlot(2, ""); tmAgain.flush();
        TrackMemory afterDeletion;
        afterDeletion.load(trackRoot, savedProject);
        check(afterDeletion.trackSlot(2).empty(), "Track position deletion did not persist");
        TrackMemory off;
        off.load(trackRoot, savedProject);
        check(!off.fixedEnabled() && off.ccLink("Track", "Volume") == "4,77",
              "Fixed CC Off must survive restart without removing the learned CC");
        // Same project name but different full path must never share edits.
        TrackMemory anotherProject;
        anotherProject.load(trackRoot, "D:\\Other\\Bass.rpp");
        check(anotherProject.file() != projectTp && anotherProject.ccLink("Track", "Volume") == "1,7" &&
            anotherProject.step("Track.Volume") == 0,
            "Unrelated projects with the same name shared MIDI or preferences");
        // Stale sessions must not overwrite externally changed project .tp.
        // Keep this instance distinct from the earlier FxOrder stale fixture.
        TrackMemory staleTrack;
        staleTrack.load(trackRoot, savedProject);
        off.setStep("Track.Volume", -8); off.flush();
        const auto newerTrackBytes = readFile(projectTp);
        staleTrack.setStep("Track.Volume", 7);
        rejected([&] { staleTrack.flush(); });
        check(readFile(projectTp) == newerTrackBytes,
            "Stale project Track profile overwritten");
        const auto trackBackup = trackRoot / L"LReaParams" / L"Backups" / L"ProfileEdits";
        check(fs::exists(trackBackup) && !fs::is_empty(trackBackup), "Project profile backup missing");
        const auto newTrackRoot = root / L"track-memory54-new";
        TrackMemory tmNew;
        tmNew.load(newTrackRoot, "E:\\Music\\Keys.rpp");
        check(!fs::exists(tmNew.file()), "Unmodified project Track map should not be created");
        tmNew.setStep("Track.Width", 5);
        tmNew.flush();
        check(parseNative(readFile(tmNew.file())).kind == ProfileKind::track &&
              !fs::exists(newTrackRoot / L"LReaParams" / L"Tracks" / L"Track CC Map.tp"),
              "New project .tp invalid or global map created by mistake");
        // Importer may still be converting the global .txt: the project uses
        // the old source as seed without creating a competing global .tp.
        const auto raceRoot = root / L"track-memory54-import-race";
        const auto raceLegacy = raceRoot / L"Scripts" / L"Lo-lo - Scripts" / L"Utility" /
            L"Scripts" / L"Tracks" / L"Track CC Map.txt";
        const auto raceNative = raceRoot / L"LReaParams" / L"Tracks" / L"Track CC Map.tp";
        overwrite(raceLegacy, oldTrackPayload);
        TrackMemory tmRace;
        tmRace.load(raceRoot, "C:\\Projects\\Race.rpp");
        tmRace.setStep("Track.Volume", -5);
        tmRace.flush();
        check(!fs::exists(raceNative) &&
            parseNative(readFile(tmRace.file())).payload.find("Volume=1,7") != std::string::npos,
            "Project save stole legacy import target or discarded its MIDI map");
        rejected([] { parseLegacy("Version=2\nF4CCScope=Plugin\n[Track]\n[Sends]\n[Receives]\n[FXParams.Plugin]\n[LReaParams.StepScales]\nTrack.Volume=11\n"); });
        rejected([] { parseLegacy("Version=2\nF4CCScope=Plugin\n[Track]\n[Sends]\n[Receives]\n[FXParams.Plugin]\n[LReaParams.ParameterSpeech]\nTrack.Pan=9\n"); });
        rejected([] { parseLegacy(
            "Version=2\nF4CCScope=ProjectTrack\n[Track]\n[Sends]\n[Receives]\n[FXParams.Plugin]\n"
            "[LReaParams.MidiSettings]\nFixedEnabled=maybe\n"); });
        const auto collision = root / L"collision.txt";
        check(writeNewVerified(collision, "first"), "Create failed");
        check(!writeNewVerified(collision, "second") && readFile(collision) == "first", "Collision replaced bytes");
        cancel = true; report = importProfiles(root, cancel); check(report.cancelled, "Cancellation ignored");
        std::cout << "Negative parsing, backup, conflicts, Unicode, idempotence, non-destructive import passed\n";
        return 0;
    } catch (const std::exception& error) { std::cerr << error.what() << '\n'; return 1; }
}
