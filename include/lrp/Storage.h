#pragma once
#include "Profile.h"
#include <filesystem>
#include <atomic>
#include <thread>
#include <mutex>
#include <optional>
#include <vector>

namespace lrp {
namespace fs = std::filesystem;
std::string readFile(const fs::path& path);
std::string sha256(const std::string& bytes);
// Creates a new file atomically; never overwrites. Existing identical bytes are OK.
bool writeNewVerified(const fs::path& path, const std::string& bytes);
struct ImportReport {
    unsigned imported = 0, fxImported = 0, trackImported = 0, unchanged = 0, conflicts = 0, rejected = 0, errors = 0, removed = 0;
    bool cancelled = false, selectedOnly = false;
    std::string summary() const;
};
ImportReport importProfiles(const fs::path& resourceRoot, const std::atomic_bool& cancel);
// Convert only explicitly selected legacy Lua TXT profiles, without moving or deleting them.
// The target directory is chosen from the parsed profile kind (FX vs Track).
ImportReport importSelectedProfiles(const fs::path& resourceRoot,
                                    const std::vector<fs::path>& sources,
                                    const std::atomic_bool& cancel);
class ImportWorker {
public:
    ~ImportWorker();
    bool start(const fs::path& resourceRoot);
    bool startSelected(const fs::path& resourceRoot, const std::vector<fs::path>& sources);
    std::optional<ImportReport> poll();
    void stop() noexcept;
private:
    std::thread worker_;
    std::atomic_bool cancel_{false}, busy_{false};
    std::mutex mutex_;
    std::optional<ImportReport> completed_;
};
}
