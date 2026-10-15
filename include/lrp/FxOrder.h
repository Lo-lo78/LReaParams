#pragma once
#include "Profile.h"
#include <filesystem>
#include <functional>
#include <map>
#include <set>
#include <string>
#include <vector>

namespace lrp {
// Lua V3 FX profiles are wrapped unchanged in the native .fx envelope.
// Do not use the ordinal FX instance GUID as the profile identity: like Lua,
// the same plugin definition shares its order, aliases and group slots.
class FxOrder {
public:
    void load(const std::filesystem::path& resource, const std::string& rawName,
              int paramCount, std::function<std::string(int)> paramName);
    bool save(); // only called after an intentional structural change
    void reset() noexcept;
    bool custom = false;
    bool groupSlotMode = false;
    std::vector<int> order; // includes hidden entries and deliberately duplicated occurrences
    std::map<int, std::string> aliases;
    std::set<int> hidden;
    std::map<int, std::vector<int>> groups; // slots 1..12, includes duplicate occurrences
    std::map<int, std::string> groupNames;
    std::map<int, int> paramSlots;
    bool hasRealModifications() const;
    bool storedCustomOrder() const noexcept;
    bool hasDefaultValues() const noexcept;
    int defaultValueCount() const noexcept;
    std::map<int,double> defaultValues() const;
    bool hasStructuralDefault() const noexcept;
    bool saveDefaultValues(const std::map<int,double>& values);
    std::map<int, std::string> ccLinks; // Lua cc_link_v1::param::n entries
    bool deleteCcLink(int param);
    void deleteCustomOrder();

    std::vector<int> visibleOrder() const;
    std::string label(int param) const;
    void normalize();
private:
    std::filesystem::path file_, resource_;
    std::string rawName_, loadedDigest_;
    std::function<std::string(int)> paramName_;
    int count_ = 0;
    Profile profile_{};
    bool loaded_ = false, existed_ = false;
};
}
