#include "lrp/TypeAhead.h"
#include <stdexcept>
#include <iostream>
#include <vector>
#include <string>
int main() {
#define CHECK(condition) do { if (!(condition)) { std::cerr << "Type-ahead failed: " #condition << " at line " << __LINE__ << "\n"; return 1; } } while (false)
    using lrp::TypeAhead;
    std::vector<std::wstring> names{L"Attack", L"Decay", L"Filter Cutoff", L"Filter Resonance", L"Frequency", L"Gain"};
    auto label = [&](int i) {return names.at(static_cast<std::size_t>(i));};
    TypeAhead search;
    int next = search.find(L'f', 100, false, 0, static_cast<int>(names.size()), false, label);
    CHECK(next == 2);
    next = search.find(L'i', 180, false, next, static_cast<int>(names.size()), false, label);
    CHECK(next == 2 && search.text() == L"fi");
    next = search.find(L'l', 240, false, next, static_cast<int>(names.size()), false, label);
    CHECK(next == 2);
    next = search.find(L'f', 1500, false, next, static_cast<int>(names.size()), false, label);
    CHECK(next == 3 && search.text() == L"f");
    next = search.find(L'f', 1570, false, next, static_cast<int>(names.size()), false, label);
    CHECK(next == 4 && search.text() == L"f"); // repeated letter cycles
    next = search.find(L'f', 1600, true, next, static_cast<int>(names.size()), false, label);
    CHECK(next == -1 && search.text() == L"f"); // key repeat ignored
    next = search.find(L'g', 1660, false, next == -1 ? 4 : next, static_cast<int>(names.size()), false, label);
    CHECK(next == 5 && search.text() == L"g"); // invalid prefix falls back
    search.reset();
    std::vector<std::wstring> eq{L"1 Mode", L"1 Frequency (Hz)", L"2 Gain", L"2 Filter Resonance"};
    auto eqLabel = [&](int i) {return eq.at(static_cast<std::size_t>(i));};
    next = search.find(L'f', 2200, false, 0, 4, false, eqLabel);
    CHECK(next == 1); // word-start search, numeric band prefix omitted
    next = search.find(L'r', 2270, false, next, 4, false, eqLabel);
    CHECK(next == 1);
    next = search.find(L'1', 4000, false, 0, 4, false, eqLabel);
    CHECK(next == 1);
    next = search.find(L'6', 4100, false, next, 4, false, eqLabel);
    CHECK(next == -1); // no matching 16 prefix in this list
    search.reset();
    next = search.find(L'f', 0xffffffffU - 200, false, 0, 4, false, eqLabel);
    CHECK(next == 1);
    next = search.find(L'r', 50, false, next, 4, false, eqLabel);
    CHECK(next == 1 && search.text() == L"fr"); // 32-bit wrap safe
    search.reset();
    std::vector<std::wstring> punctuation{L"Attack", L"#Shape", L"(Width)", L"-Gain"};
    auto punLabel = [&](int i) {return punctuation.at(static_cast<std::size_t>(i));};
    next = search.find(L'#', 6000, false, 0, 4, false, punLabel);
    CHECK(next == 1);
    next = search.find(L'(', 8200, false, next, 4, false, punLabel);
    CHECK(next == 2);
    search.reset();
    next = search.find(L'f', 9000, false, 4, static_cast<int>(names.size()), true, label);
    CHECK(next == 3); // Shift+F searches backward
    std::cout << "Type-ahead C++ tests passed\n";
}
