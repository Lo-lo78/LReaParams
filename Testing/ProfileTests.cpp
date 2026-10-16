#include "lrp/Profile.h"
#include "lrp/Storage.h"
#include "lrp/FxOrder.h"
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
        check(reopened.deleteCcLink(1),"Hidden CC deletion failed");
        FxOrder cleared;
        cleared.load(profileRoot,"Synthetic edit test",4,[](int id){return id==compareParamIndex?std::string("Compare"):"Parameter "+std::to_string(id);});
        check(!cleared.ccLinks.count(1),"Deleted hidden CC reappeared");
        const auto collision = root / L"collision.txt";
        check(writeNewVerified(collision, "first"), "Create failed");
        check(!writeNewVerified(collision, "second") && readFile(collision) == "first", "Collision replaced bytes");
        cancel = true; report = importProfiles(root, cancel); check(report.cancelled, "Cancellation ignored");
        std::cout << "Negative parsing, backup, conflicts, Unicode, idempotence, non-destructive import passed\n";
        return 0;
    } catch (const std::exception& error) { std::cerr << error.what() << '\n'; return 1; }
}
