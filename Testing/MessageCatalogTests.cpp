#include "lrp/MessageCatalog.h"
#include <cassert>
#include <string>
#include <set>
#include <iostream>
using namespace lrp;
int main() {
    const auto& messages = speechMessageCatalog();
    std::set<std::string> ids;
    int fx = 0, track = 0;
    for (const auto& item : messages) {
        assert(ids.insert(item.id).second && !item.label.empty());
        if (item.scope == SpeechScope::fx) ++fx;
        else ++track;
    }
    assert(fx > 250 && track > 200);
    const std::string id = speechMessageId(SpeechScope::fx, "C:\\src\\FxNavigator.cpp", "\"No track FX\"");
    assert(ids.count(id));
    std::string announced;
    auto output = [&](const std::string& value){ announced = value; };
    setSpeechMessageOverrides({});
    emitConfigurableSpeech(SpeechScope::fx, "FxNavigator.cpp", "\"No track FX\"", output, "No track FX");
    assert(announced == "No track FX");
    setSpeechMessageOverrides({{id, false, L""}});
    announced.clear();
    emitConfigurableSpeech(SpeechScope::fx, "FxNavigator.cpp", "\"No track FX\"", output, "No track FX");
    assert(announced.empty());
    setSpeechMessageOverrides({{id, true, L"Custom: {original}"}});
    emitConfigurableSpeech(SpeechScope::fx, "FxNavigator.cpp", "\"No track FX\"", output, "No track FX");
    assert(announced == "Custom: No track FX");
    // Same text under the other navigator cannot inherit FX settings.
    emitConfigurableSpeech(SpeechScope::track, "TrackNavigator.cpp", "\"No track FX\"", output, "No track FX");
    assert(announced == "No track FX");
    setSpeechMessageOverrides({});
    std::cout << "Message catalog test PASS: FX=" << fx << ", Track=" << track << "\n";
}
