add_unit_test(
    catch2_test
    CATCH2
    COVERAGE
    FILES
    catch2_test.cpp
    LIBRARIES
    diagnostics
    warnings)

add_unit_test(
    gtest_test
    GTEST
    COVERAGE
    FILES
    gtest_test.cpp
    LIBRARIES
    diagnostics
    warnings)

add_unit_test(
    gunit_test
    GUNIT
    COVERAGE
    FILES
    gunit_test.cpp
    LIBRARIES
    diagnostics
    warnings)
target_compile_features(gunit_test PRIVATE cxx_std_17)

add_unit_test(
    snitch_test
    SNITCH
    COVERAGE
    FILES
    snitch_test.cpp
    LIBRARIES
    diagnostics
    warnings)

add_unit_test(
    custom_test
    COVERAGE
    FILES
    custom_test.cpp
    LIBRARIES
    diagnostics
    warnings)

add_feature_test(
    gunit_feature_test
    COVERAGE
    FILES
    gunit_steps.cpp
    FEATURE
    test.feature
    LIBRARIES
    diagnostics
    warnings)

add_fuzz_test(
    fuzz_test
    COVERAGE
    FILES
    fuzz_test.cpp
    LIBRARIES
    diagnostics
    warnings)

add_compile_fail_test(compile_fail_test.cpp LIBRARIES diagnostics warnings)
add_compile_fail_test(compile_fail_test_no_pattern.cpp LIBRARIES diagnostics
                      warnings)

add_unit_test(
    nonrandom_test
    CATCH2
    NORANDOM
    COVERAGE
    FILES
    nonrandom_test.cpp
    LIBRARIES
    diagnostics
    warnings)

add_unit_test(pytest_test PYTEST FILES pytest_test.py EXTRA_ARGS --pass)
mypy_lint(FILES pytest_test.py)

add_benchmark(
    nanobm_test
    NANO
    FILES
    nanobm_test.cpp
    LIBRARIES
    diagnostics
    warnings)
