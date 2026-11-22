#pragma once
#include <functional>
#include <string>
#include <vector>
namespace lrp {
enum class SpeechScope { fx, track };
struct SpeechMessageDefinition {
    SpeechScope scope;
    std::string id;
    std::string label;
};
struct SpeechMessageOverride {
    std::string id;
    bool enabled = true;
    std::wstring custom;
};
const std::vector<SpeechMessageDefinition>& speechMessageCatalog();
std::string speechMessageId(SpeechScope scope, const char* file, const char* expression);
void setSpeechMessageOverrides(const std::vector<SpeechMessageOverride>& values);
void emitConfigurableSpeech(SpeechScope scope, const char* file, const char* expression,
    const std::function<void(const std::string&)>& output, const std::string& message);
}
