#include "lrp/Storage.h"
#include <windows.h>
#include <bcrypt.h>
#include <vector>
#include <sstream>
#include <iomanip>
#include <algorithm>
#include <cwctype>

namespace lrp {
namespace {
struct Handle {
    HANDLE value = INVALID_HANDLE_VALUE;
    explicit Handle(HANDLE h) : value(h) {}
    ~Handle() { if (value != INVALID_HANDLE_VALUE) CloseHandle(value); }
    Handle(const Handle&) = delete;
    Handle& operator=(const Handle&) = delete;
};
std::string readHandle(HANDLE handle) {
    LARGE_INTEGER size{};
    if (!GetFileSizeEx(handle, &size) || size.QuadPart < 0 || size.QuadPart > static_cast<LONGLONG>(maxProfileBytes + 150))
        throw ProfileError("Invalid file size");
    std::string bytes(static_cast<std::size_t>(size.QuadPart), '\0'); DWORD actual = 0;
    if (!ReadFile(handle, bytes.data(), static_cast<DWORD>(bytes.size()), &actual, nullptr) || actual != bytes.size())
        throw ProfileError("File read failed");
    return bytes;
}
bool reparse(const fs::path& p) {
    const DWORD a = GetFileAttributesW(p.c_str());
    if (a == INVALID_FILE_ATTRIBUTES) return false;
    return (a & FILE_ATTRIBUTE_REPARSE_POINT) != 0;
}
void ensurePlainTree(const fs::path& p) {
    // Refuse junctions/symlinks, including ancestors of an existing destination.
    for (auto q = p; !q.empty(); q = q.parent_path()) {
        if (reparse(q)) throw ProfileError("Reparse path refused");
        if (q == q.parent_path()) break;
    }
}
void makeDirectory(const fs::path& p) { ensurePlainTree(p); fs::create_directories(p); }
std::wstring lower(std::wstring s) { std::transform(s.begin(), s.end(), s.begin(), [](wchar_t c) { return static_cast<wchar_t>(std::towlower(c)); }); return s; }
}
std::string readFile(const fs::path& p) {
    Handle handle(CreateFileW(p.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr));
    if (handle.value == INVALID_HANDLE_VALUE) throw ProfileError("Cannot read file");
    return readHandle(handle.value);
}
std::string sha256(const std::string& bytes) {
    struct Algorithm { BCRYPT_ALG_HANDLE handle{}; ~Algorithm() { if (handle) BCryptCloseAlgorithmProvider(handle, 0); } } algorithm;
    if (BCryptOpenAlgorithmProvider(&algorithm.handle, BCRYPT_SHA256_ALGORITHM, nullptr, 0) < 0) throw ProfileError("SHA256 unavailable");
    DWORD objectSize = 0, cb = 0;
    if (BCryptGetProperty(algorithm.handle, BCRYPT_OBJECT_LENGTH, reinterpret_cast<PUCHAR>(&objectSize), sizeof(objectSize), &cb, 0) < 0)
        throw ProfileError("SHA256 property failed");
    std::vector<unsigned char> object(objectSize), digest(32);
    struct Hash { BCRYPT_HASH_HANDLE handle{}; ~Hash() { if (handle) BCryptDestroyHash(handle); } } hash;
    if (BCryptCreateHash(algorithm.handle, &hash.handle, object.data(), objectSize, nullptr, 0, 0) < 0 ||
        BCryptHashData(hash.handle, reinterpret_cast<PUCHAR>(const_cast<char*>(bytes.data())), static_cast<ULONG>(bytes.size()), 0) < 0 ||
        BCryptFinishHash(hash.handle, digest.data(), static_cast<ULONG>(digest.size()), 0) < 0) throw ProfileError("SHA256 failed");
    std::ostringstream out; out << std::hex << std::setfill('0');
    for (unsigned char c : digest) out << std::setw(2) << static_cast<unsigned>(c);
    return out.str();
}
bool writeNewVerified(const fs::path& path, const std::string& bytes) {
    ensurePlainTree(path); makeDirectory(path.parent_path());
    if (fs::exists(path)) return readFile(path) == bytes;
    static std::atomic_uint serial{0};
    auto temporary = path;
    temporary += L".tmp-" + std::to_wstring(GetCurrentProcessId()) + L"-" + std::to_wstring(++serial);
    // CREATE_NEW avoids touching stale or preexisting temporary files.
    {
        Handle handle(CreateFileW(temporary.c_str(), GENERIC_WRITE, 0, nullptr, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, nullptr));
        if (handle.value == INVALID_HANDLE_VALUE) throw ProfileError("Cannot create temporary file");
        DWORD actual = 0;
        if (!WriteFile(handle.value, bytes.data(), static_cast<DWORD>(bytes.size()), &actual, nullptr) || actual != bytes.size() || !FlushFileBuffers(handle.value))
            throw ProfileError("Cannot flush temporary file; original unchanged");
    }
    if (readFile(temporary) != bytes) throw ProfileError("Temporary verification failed");
    if (!MoveFileExW(temporary.c_str(), path.c_str(), MOVEFILE_WRITE_THROUGH)) {
        // Another process may have won the create. Never replace its file.
        const bool identical = fs::exists(path) && readFile(path) == bytes;
        std::error_code ignored; fs::remove(temporary, ignored);
        if (!identical) return false;
    }
    return readFile(path) == bytes;
}
std::string ImportReport::summary() const {
    return "Import: " + std::to_string(imported) + " converted, " + std::to_string(unchanged) + " unchanged, " +
        std::to_string(conflicts) + " conflicts, " + std::to_string(rejected) + " unrecognized, " +
        std::to_string(errors) + " errors, " + std::to_string(removed) + " active TXT removed" + (cancelled ? ". Cancelled" : "");
}
ImportReport importProfiles(const fs::path& resource, const std::atomic_bool& cancel) {
    ImportReport result;
    const auto root = resource / L"LReaParams";
    try { for (const auto* name : {L"Plugins", L"Params", L"Tracks", L"Settings", L"Backups"}) makeDirectory(root / name); }
    catch (...) { ++result.errors; return result; }
    const auto legacy = resource / L"Scripts" / L"Lo-lo - Scripts" / L"Utility" / L"Scripts";
    struct Branch { const wchar_t* name; ProfileKind kind; };
    for (const auto& branch : {Branch{L"Plugins", ProfileKind::fx}, Branch{L"Params", ProfileKind::library}, Branch{L"Tracks", ProfileKind::track}}) {
        for (bool active : {false, true}) {
            const auto from = (active ? root : legacy) / branch.name;
            try {
                ensurePlainTree(from);
                if (!fs::exists(from)) continue;
                for (auto it = fs::recursive_directory_iterator(from); it != fs::recursive_directory_iterator(); ++it) {
                    if (cancel) { result.cancelled = true; return result; }
                    if (reparse(it->path())) { if (it->is_directory()) it.disable_recursion_pending(); continue; }
                    if (!it->is_regular_file() || lower(it->path().extension().wstring()) != L".txt") continue;
                    const auto name = lower(it->path().filename().wstring());
                    if (name == L"_parameter library handoff.txt" || name == L"_parameter library return.txt") { ++result.rejected; continue; }
                    try {
                        const auto source = it->path();
                        ensurePlainTree(source);
                        // Hold source locked against writers and renames through verification and delete.
                        Handle sourceHandle(CreateFileW(source.c_str(), GENERIC_READ | (active ? DELETE : 0), FILE_SHARE_READ,
                            nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr));
                        if (sourceHandle.value == INVALID_HANDLE_VALUE) throw ProfileError("Source is busy or inaccessible");
                        const auto bytes = readHandle(sourceHandle.value);
                        Profile p;
                        try { p = parseLegacy(bytes); } catch (const ProfileError&) { ++result.rejected; continue; }
                        if (p.kind != branch.kind) { ++result.rejected; continue; }
                        const auto relative = source.lexically_relative(from);
                        auto target = root / branch.name / relative; target.replace_extension(extension(p.kind));
                        const auto native = serializeNative(p), fingerprint = sha256(bytes);
                        const auto recordId = sha256(source.u8string()) + "-" + fingerprint;
                        const auto marker = root / L"Settings" / L"Imports" / fs::u8path(recordId + ".record");
                        const std::string record = "LREAPARAMS_IMPORT_V1\nSourceSHA256=" + fingerprint + "\nPayloadBytes=" + std::to_string(bytes.size()) + "\n";
                        ensurePlainTree(target);
                        if (fs::exists(target) && readFile(target) != native) {
                            // An already imported source must not overwrite a later user edit.
                            if (fs::exists(marker) && readFile(marker) == record) { ++result.unchanged; continue; }
                            auto candidate = root / L"Settings" / L"ImportConflicts" / branch.name / relative;
                            candidate += fs::u8path("." + fingerprint + extension(p.kind));
                            if (!writeNewVerified(candidate, native)) throw ProfileError("Conflict candidate collision");
                            ++result.conflicts; continue;
                        }
                        const bool existed = fs::exists(target);
                        auto backup = root / L"Backups" / fs::u8path(fingerprint + ".txt");
                        if (!writeNewVerified(backup, bytes)) throw ProfileError("Backup collision");
                        if (cancel) { result.cancelled = true; return result; }
                        if (!writeNewVerified(target, native)) { ++result.conflicts; continue; }
                        if (parseNative(readFile(target)).payload != bytes) throw ProfileError("Target verification failed");
                        if (!writeNewVerified(marker, record)) throw ProfileError("Import record collision");
                        if (active) {
                            FILE_DISPOSITION_INFO dispose{TRUE};
                            if (!SetFileInformationByHandle(sourceHandle.value, FileDispositionInfo, &dispose, sizeof(dispose)))
                                throw ProfileError("Converted, but TXT deletion failed");
                            ++result.removed;
                        }
                        if (existed) ++result.unchanged; else ++result.imported;
                    } catch (...) { ++result.errors; }
                }
            } catch (...) { ++result.errors; }
        }
    }
    return result;
}
ImportWorker::~ImportWorker() { stop(); }
bool ImportWorker::start(const fs::path& root) {
    if (busy_) return false;
    if (worker_.joinable()) worker_.join();
    { std::lock_guard<std::mutex> lock(mutex_); completed_.reset(); }
    cancel_ = false; busy_ = true;
    try {
        worker_ = std::thread([this, root] {
            ImportReport report;
            try { report = importProfiles(root, cancel_); } catch (...) { ++report.errors; }
            { std::lock_guard<std::mutex> lock(mutex_); completed_ = report; }
            busy_ = false;
        });
    } catch (...) { busy_ = false; throw; }
    return true;
}
std::optional<ImportReport> ImportWorker::poll() {
    if (busy_) return {};
    if (worker_.joinable()) worker_.join();
    std::lock_guard<std::mutex> lock(mutex_);
    auto report = completed_; completed_.reset(); return report;
}
void ImportWorker::stop() noexcept { cancel_ = true; if (worker_.joinable()) worker_.join(); }
}
