#include <gmock/gmock.h>
#include <gtest/gtest.h>
#include <rapidcheck/gtest.h>

TEST(tests, gtest_test) { EXPECT_EQ(42, 42); }

struct interface {
    virtual ~interface() = default;
    virtual void foo(int) = 0;
};

struct mock_interface : interface {
    MOCK_METHOD1(foo, void(int));
};

TEST(tests, gmock_test) {
    testing::StrictMock<mock_interface> mock{};
    EXPECT_CALL(mock, foo(42));
    interface &i = mock;
    i.foo(42);
}

RC_GTEST_PROP(tests, rapidcheck_test, (int a, int b)) {
    RC_ASSERT(a + b == b + a);
}
