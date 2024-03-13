from hypothesis import given, strategies as st

small_ints = st.integers(min_value=0, max_value=1000)

@given(small_ints, small_ints)
def test_addition_is_commutative(a: int, b: int):
    assert a + b == b + a
