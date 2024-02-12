#include <catch2/catch_test_macros.hpp>
#include <rapidcheck/catch.h>

namespace {
bool run_order{};
}

TEST_CASE("nonrandom test part 1", "[nonrandom_test]") { run_order = true; }

TEST_CASE("nonrandom test part 2", "[nonrandom_test]") { CHECK(run_order); }
