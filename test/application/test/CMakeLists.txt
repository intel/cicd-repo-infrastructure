add_unit_test(catch2_test CATCH2 FILES catch2_test.cpp LIBRARIES warnings)
add_unit_test(gtest_test GTEST FILES gtest_test.cpp LIBRARIES warnings)

add_unit_test(gunit_test GUNIT FILES gunit_test.cpp LIBRARIES warnings)
target_compile_features(gunit_test PRIVATE cxx_std_17)

add_unit_test(custom_test FILES custom_test.cpp LIBRARIES warnings)
add_feature_test(
    gunit_feature_test
    FILES
    gunit_steps.cpp
    FEATURE
    test.feature
    LIBRARIES
    warnings)
