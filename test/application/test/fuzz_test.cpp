#include <fuzztest/fuzztest.h>
#include <gtest/gtest.h>

namespace {
void integer_addition_commutes(unsigned int a, unsigned int b) {
    EXPECT_EQ(a + b, b + a);
}
} // namespace

FUZZ_TEST(tests, integer_addition_commutes);
