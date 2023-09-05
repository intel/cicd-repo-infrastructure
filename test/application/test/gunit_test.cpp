#include <GUnit.h>
#include <rapidcheck/gtest.h>

namespace {
struct interface {
    virtual ~interface() = default;
    virtual auto foo(int) -> void = 0;
};

struct thing {
    thing(interface &iface) : i{iface} {}
    auto foo(int n) -> void { i.foo(n); }
    interface &i;
};

struct impl : interface {
    int value{};
    auto foo(int i) -> void final { value = i; }
};
} // namespace

GTEST("gunit tests") {
    using namespace testing;
    namespace di = boost::di;

    SHOULD("run a plain test") { EXPECT(5 == 3 + 2); }

    SHOULD("run a mock test") {
        StrictGMock<interface> mock{};
        EXPECT_CALL(mock, (foo)(42));
        interface &i = mock.object();
        i.foo(42);
    }

    SHOULD("use implicit mocks") {
        auto [s, m] = make<thing, StrictGMock>();
        EXPECT_CALL(m.mock<interface>(), (foo)(42));
        s.foo(42);
    }

    SHOULD("use DI for a test") {
        impl i;
        auto const injector = di::make_injector(di::bind<interface>.to(i));
        auto s = make<thing>(injector);
        s.foo(42);
        EXPECT_EQ(i.value, 42);
    }
}

RC_GTEST_PROP(tests, rapidcheck_test, (int a, int b)) {
    RC_ASSERT(a + b == b + a);
}
