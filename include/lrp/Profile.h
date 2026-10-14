#pragma once
#include <cstddef>
#include <string>
#include <string_view>
#include <vector>
#include <map>
#include <stdexcept>

namespace lrp {
enum class ProfileKind { fx, track, library };
struct ProfileError : std::runtime_error { using std::runtime_error::runtime_error; };
struct Field { std::string key, value; };
struct Profile {
    ProfileKind kind{};
    // Original bytes are authoritative: do not reformat decimal strings or escapes.
    std::string payload;
    std::map<std::string, std::string> headers;
    std::map<std::string, std::vector<std::string>> sections;
    std::vector<std::vector<std::string>> records;
};
constexpr std::size_t maxProfileBytes = 32 * 1024 * 1024;
Profile parseLegacy(std::string bytes);
Profile parseNative(std::string bytes);
std::string serializeNative(const Profile& profile);
const char* kindName(ProfileKind kind) noexcept;
const char* extension(ProfileKind kind) noexcept;
std::vector<std::string> split(std::string_view s, char delimiter);
}
