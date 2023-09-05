#include <catch2/catch_test_macros.hpp>
#include <rapidcheck/catch.h>

TEST_CASE("catch2 test", "[test]") {}

TEST_CASE("catch2 with rapidcheck", "[test]") {
    rc::prop("test property", [](int a, int b) { return a + b == b + a; });
}
