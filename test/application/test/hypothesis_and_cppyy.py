from cppyy.gbl import std
from cppyy.ll import static_cast
from hypothesis import given, strategies as strat

small_ints = strat.integers(min_value=0, max_value=1000)

@given(small_ints, small_ints)
def test_addition_on_ints_is_commutative(a : int, b : int):
    a = static_cast[std.uint32_t](a)
    b = static_cast[std.uint32_t](b)
    assert a + b == b + a

@given(small_ints)
def test_value_of_integral_constant(a : int):
    a = static_cast[std.uint32_t](a)
    ica = std.integral_constant[std.uint32_t, a]()
    assert ica.value == a