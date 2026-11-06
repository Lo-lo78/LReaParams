// TEST64.1 pure keyboard mapping and 14-context persistence tests.
#include "lrp/KeyboardTheme.h"
#include <cassert>
#include <string>

int main() {
    using namespace lrp::keyboard;
    assert(keys.size() == 36);
    const std::string expected = "1234567890QWERTYUIOPASDFGHJKLZXCVBNM";
    for (int i = 0; i < pageSize; ++i) {
        assert(offset(static_cast<unsigned char>(expected[static_cast<std::size_t>(i)])) == i);
        assert(keyTarget(0, i, 100) == i);
        assert(keyTarget(44, i, 100) == 36 + i);
        assert(keyTarget(72, i, 100) == (72+i<100?72+i:-1));
    }
    assert(offset('q') == -1); // Windows VK codes are uppercase.
    assert(offset(0x25) == -1); // Left arrow is never a direct selection.
    assert(offset('!') == -1);
    assert(pageTarget(0, 1, 100) == 36);
    assert(pageTarget(71, 1, 100) == 72);
    assert(pageTarget(80, -1, 100) == 36);
    assert(pageTarget(0, -1, 100) == -1);
    assert(pageTarget(99, 1, 100) == -1);
    assert(pageTarget(35, 1, 36) == -1);
    assert(pageTarget(36, -1, 37) == 0);
    assert(pageTarget(0, 1, 0) == -1);
    assert(keyTarget(0, 35, 15) == -1);
    assert(keyTarget(0, 0, 0) == -1);
    std::array<bool,contextCount> themes{};
    assert(encode(themes).empty());
    assert(decode("") == themes);
    assert(decode("101") == themes);
    assert(decode("0000000000000x") == themes);
    themes[0] = true; themes[1] = true; themes[13] = true;
    assert(encode(themes) == "11000000000001");
    assert(decode(encode(themes)) == themes);
    themes[0] = false;
    assert(decode(encode(themes))[0] == false);
    assert(decode(encode(themes))[1] == true);
    assert(decode(encode(themes))[13] == true);
    return 0;
}
