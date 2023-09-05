#include <GUnit.h>

GSTEPS("Test*") {
    Given("I have a given value of {x}") = [&](int x) {
        auto result = x;
        When("I add {y}") = [&](int y) { result += y; };
        Then("The result should be {z}") = [&](int z) { EXPECT(z == result); };
    };
}
