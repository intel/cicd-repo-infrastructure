#pragma once

// this file is purposefully excluded from clang-tidy
struct Violator {
    auto f() const -> unsigned long long { return 1729ull; }
};
