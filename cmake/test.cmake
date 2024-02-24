cmake_minimum_required(VERSION 3.25)

option(BUILD_TESTING "" OFF)
include(CTest)
add_custom_target(unit_tests)
add_custom_target(build_unit_tests)
set(CMAKE_TESTING_ENABLED
    1
    CACHE INTERNAL "")

find_program(MEMORYCHECK_COMMAND NAMES valgrind)
set(MEMORYCHECK_SUPPRESSIONS_FILE
    "${CMAKE_CURRENT_LIST_DIR}/default.supp"
    CACHE FILEPATH "File that contains suppressions for the memory checker")
set(MEMORYCHECK_COMMAND_OPTIONS
    "-q --tool=memcheck --show-reachable=yes --num-callers=50"
    CACHE FILEPATH "Valgrind options")
configure_file(${CMAKE_ROOT}/Modules/DartConfiguration.tcl.in
               ${PROJECT_BINARY_DIR}/DartConfiguration.tcl)

macro(get_catch2)
    if(NOT TARGET Catch2::Catch2WithMain)
        add_versioned_package("gh:catchorg/Catch2@3.5.0")
        list(APPEND CMAKE_MODULE_PATH ${Catch2_SOURCE_DIR}/extras)
        include(Catch)
    endif()
endmacro()

macro(get_gtest)
    if(NOT TARGET gtest)
        add_versioned_package("gh:google/googletest@1.14.0")
        include(GoogleTest)
    endif()
endmacro()

macro(get_gunit)
    get_gtest()
    if(NOT DEFINED gunit_SOURCE_DIR)
        add_versioned_package(
            NAME
            gunit
            GIT_TAG
            v1.14.0
            GITHUB_REPOSITORY
            cpp-testing/GUnit
            DOWNLOAD_ONLY
            YES)
    endif()
endmacro()

macro(get_fuzztest)
    if(NOT TARGET fuzztest)
        add_versioned_package(
            NAME
            fuzztest
            GIT_TAG
            a4f6ad5
            GITHUB_REPOSITORY
            google/fuzztest
            OPTIONS
            "ANTLR_BUILD_CPP_TESTS OFF"
            "ANTLR_BUILD_SHARED OFF")
    endif()
endmacro()

macro(add_boost_di)
    if(NOT TARGET Boost.DI)
        add_versioned_package("gh:boost-ext/di@1.3.0")
    endif()
endmacro()

macro(add_gherkin)
    if(NOT TARGET gherkin-cpp)
        add_subdirectory(
            ${gunit_SOURCE_DIR}/libs/gherkin-cpp
            ${gunit_BINARY_DIR}/libs/gherkin-cpp EXCLUDE_FROM_ALL SYSTEM)
    endif()
endmacro()

macro(add_rapidcheck)
    if(NOT TARGET rapidcheck)
        add_versioned_package(NAME rapidcheck GIT_TAG 1c91f40 GITHUB_REPOSITORY
                              emil-e/rapidcheck)
        add_subdirectory(
            ${rapidcheck_SOURCE_DIR}/extras/catch
            ${rapidcheck_BINARY_DIR}/extras/catch EXCLUDE_FROM_ALL SYSTEM)
        add_subdirectory(
            ${rapidcheck_SOURCE_DIR}/extras/gtest
            ${rapidcheck_BINARY_DIR}/extras/gtest EXCLUDE_FROM_ALL SYSTEM)
        add_subdirectory(
            ${rapidcheck_SOURCE_DIR}/extras/gmock
            ${rapidcheck_BINARY_DIR}/extras/gmock EXCLUDE_FROM_ALL SYSTEM)
    endif()
endmacro()

function(add_unit_test_target name)
    set(options CATCH2 GTEST GUNIT NORANDOM)
    set(multiValueArgs FILES INCLUDE_DIRECTORIES LIBRARIES SYSTEM_LIBRARIES)
    cmake_parse_arguments(UNIT "${options}" "" "${multiValueArgs}" ${ARGN})

    add_executable(${name} ${UNIT_FILES})
    target_include_directories(${name} PRIVATE ${UNIT_INCLUDE_DIRECTORIES})
    target_link_libraries(${name} PRIVATE ${UNIT_LIBRARIES})
    target_link_libraries_system(${name} PRIVATE ${UNIT_SYSTEM_LIBRARIES})
    target_link_libraries(${name} PRIVATE sanitizers)
    add_dependencies(build_unit_tests ${name})

    if(UNIT_CATCH2)
        target_link_libraries_system(${name} PRIVATE Catch2::Catch2WithMain
                                     rapidcheck rapidcheck_catch)
        if(UNIT_NORANDOM)
            message(
                WARNING
                    "${name} is set to NORANDOM: unrandomized tests are not best practice"
            )
            set(target_test_command $<TARGET_FILE:${name}>)
            add_test(NAME ${name} COMMAND ${target_test_command})
        else()
            set(target_test_command $<TARGET_FILE:${name}> "--order" "rand")
            if(DEFINED ENV{CI})
                add_test(NAME ${name} COMMAND ${target_test_command})
            else()
                catch_discover_tests(${name})
            endif()
        endif()
    elseif(UNIT_GTEST)
        target_link_libraries_system(
            ${name}
            PRIVATE
            gmock
            gtest
            gmock_main
            rapidcheck
            rapidcheck_gtest
            rapidcheck_gmock)
        if(UNIT_NORANDOM)
            message(
                WARNING
                    "${name} is set to NORANDOM: unrandomized tests are not best practice"
            )
            set(target_test_command $<TARGET_FILE:${name}>)
            add_test(NAME ${name} COMMAND ${target_test_command})
        else()
            set(target_test_command $<TARGET_FILE:${name}> "--gtest_shuffle")
            if(DEFINED ENV{CI})
                add_test(NAME ${name} COMMAND ${target_test_command})
            else()
                gtest_discover_tests(${name})
            endif()
        endif()
    elseif(UNIT_GUNIT)
        target_include_directories(
            ${name} SYSTEM
            PRIVATE ${gunit_SOURCE_DIR}/include
                    ${gunit_SOURCE_DIR}/libs/json/single_include/nlohmann)
        target_link_libraries_system(
            ${name}
            PRIVATE
            gtest_main
            gmock_main
            Boost.DI
            rapidcheck
            rapidcheck_gtest
            rapidcheck_gmock)
        target_compile_options(${name} PRIVATE "-fno-sanitize=vptr")
        if(UNIT_NORANDOM)
            message(
                WARNING
                    "${name} is set to NORANDOM: unrandomized tests are not best practice"
            )
            set(target_test_command $<TARGET_FILE:${name}>)
        else()
            set(target_test_command $<TARGET_FILE:${name}> "--gtest_shuffle")
        endif()
        add_test(NAME ${name} COMMAND ${target_test_command})
    else()
        set(target_test_command $<TARGET_FILE:${name}>)
        add_test(NAME ${name} COMMAND ${target_test_command})
    endif()

    add_custom_target(all_${name} ALL DEPENDS run_${name})
    add_custom_target(run_${name} DEPENDS ${name}.passed)
    add_custom_command(
        OUTPUT ${name}.passed
        COMMAND ${target_test_command}
        COMMAND ${CMAKE_COMMAND} "-E" "touch" "${name}.passed"
        DEPENDS ${name})

    add_dependencies(unit_tests "run_${name}")
endfunction()

function(detect_test_framework)
    set(options CATCH2 GTEST GUNIT)
    cmake_parse_arguments(TF "${options}" "" "" ${ARGN})
    return(PROPAGATE TF_CATCH2 TF_GTEST TF_GUNIT)
endfunction()

macro(add_unit_test)
    detect_test_framework(${ARGN})
    if(TF_CATCH2)
        get_catch2()
        add_rapidcheck()
        unset(TF_CATCH)
    endif()
    if(TF_GTEST)
        get_gtest()
        add_rapidcheck()
        unset(TF_GTEST)
    endif()
    if(TF_GUNIT)
        get_gunit()
        add_boost_di()
        add_rapidcheck()
        unset(TF_GUNIT)
    endif()
    add_unit_test_target(${ARGN})
endmacro()

function(add_feature_test_target name)
    set(singleValueArgs FEATURE NORANDOM)
    set(multiValueArgs FILES INCLUDE_DIRECTORIES LIBRARIES SYSTEM_LIBRARIES)
    cmake_parse_arguments(FEAT "" "${singleValueArgs}" "${multiValueArgs}"
                          ${ARGN})

    add_executable(${name} ${FEAT_FILES})
    target_include_directories(${name} PRIVATE ${FEAT_INCLUDE_DIRECTORIES})
    target_link_libraries(${name} PRIVATE ${FEAT_LIBRARIES})
    target_link_libraries_system(${name} PRIVATE ${FEAT_SYSTEM_LIBRARIES})
    target_link_libraries(${name} PRIVATE sanitizers)
    add_dependencies(build_unit_tests ${name})

    target_include_directories(
        ${name} SYSTEM
        PRIVATE ${gunit_SOURCE_DIR}/include
                ${gunit_SOURCE_DIR}/libs/json/single_include/nlohmann
                ${rapidcheck_SOURCE_DIR}/extras/gmock/include)
    target_link_libraries_system(
        ${name}
        PRIVATE
        gtest_main
        gmock_main
        gherkin-cpp
        Boost.DI
        rapidcheck
        rapidcheck_gtest
        rapidcheck_gmock)
    if(FEAT_NORANDOM)
        message(
            WARNING
                "${name} is set to NORANDOM: unrandomized tests are not best practice"
        )
        set(target_test_command $<TARGET_FILE:${name}>)
    else()
        set(target_test_command $<TARGET_FILE:${name}> "--gtest_shuffle")
    endif()
    add_test(NAME ${name} COMMAND ${target_test_command})

    add_custom_target(all_${name} ALL DEPENDS run_${name})
    add_custom_target(run_${name} DEPENDS ${name}.passed ${FEAT_FEATURE})
    get_filename_component(FEATURE_FILE ${FEAT_FEATURE} ABSOLUTE)
    add_custom_command(
        OUTPUT ${name}.passed
        COMMAND ${CMAKE_COMMAND} -E env SCENARIO="${FEATURE_FILE}"
                ${target_test_command}
        COMMAND ${CMAKE_COMMAND} "-E" "touch" "${name}.passed"
        DEPENDS ${name})

    set_property(TEST ${name} PROPERTY ENVIRONMENT "SCENARIO=${FEATURE_FILE}")
    add_dependencies(unit_tests "run_${name}")
endfunction()

macro(add_feature_test)
    get_gunit()
    add_gherkin()
    add_boost_di()
    add_rapidcheck()
    add_feature_test_target(${ARGN})
endmacro()

function(add_fuzz_test_target name)
    set(singleValueArgs NORANDOM)
    set(multiValueArgs FILES INCLUDE_DIRECTORIES LIBRARIES SYSTEM_LIBRARIES)
    cmake_parse_arguments(FUZZ "" "" "${multiValueArgs}" ${ARGN})

    add_executable(${name} ${FUZZ_FILES})
    target_include_directories(${name} PRIVATE ${FUZZ_INCLUDE_DIRECTORIES})
    target_link_libraries(${name} PRIVATE ${FUZZ_LIBRARIES})
    target_link_libraries_system(${name} PRIVATE ${FUZZ_SYSTEM_LIBRARIES})
    add_dependencies(build_unit_tests ${name})

    target_compile_definitions(
        ${name} PRIVATE FUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION
                        ADDRESS_SANITIZER)
    target_compile_options(
        ${name} PRIVATE -g -UNDEBUG -fsanitize-coverage=inline-8bit-counters
                        -fsanitize-coverage=trace-cmp -fsanitize=address)
    target_link_options(${name} PRIVATE -fsanitize=address)

    target_link_libraries_system(
        ${name}
        PRIVATE
        gmock
        gtest
        rapidcheck
        rapidcheck_gtest
        rapidcheck_gmock
        fuzztest::fuzztest_gtest_main)
    if(FUZZ_NORANDOM)
        message(
            WARNING
                "${name} is set to NORANDOM: unrandomized tests are not best practice"
        )
        set(target_test_command $<TARGET_FILE:${name}>)
        add_test(NAME ${name} COMMAND ${target_test_command})
    else()
        set(target_test_command $<TARGET_FILE:${name}> "--gtest_shuffle")
        if(DEFINED ENV{CI})
            add_test(NAME ${name} COMMAND ${target_test_command})
        else()
            gtest_discover_tests(${name})
        endif()
    endif()

    add_custom_target(all_${name} ALL DEPENDS run_${name})
    add_custom_target(run_${name} DEPENDS ${name}.passed)
    add_custom_command(
        OUTPUT ${name}.passed
        COMMAND ${target_test_command}
        COMMAND ${CMAKE_COMMAND} "-E" "touch" "${name}.passed"
        DEPENDS ${name})

    add_dependencies(unit_tests "run_${name}")
endfunction()

macro(add_fuzz_test)
    if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        get_gtest()
        get_fuzztest()
        add_rapidcheck()
        add_fuzz_test_target(${ARGN})
    else()
        message(
            STATUS
                "add_fuzz_test(${ARGN}) is disabled because CMAKE_CXX_COMPILER_ID is ${CMAKE_CXX_COMPILER_ID}."
        )
    endif()
endmacro()

function(add_compile_fail_test test_file)
    set(multiValueArgs INCLUDE_DIRECTORIES LIBRARIES SYSTEM_LIBRARIES)
    cmake_parse_arguments(CF "" "" "${multiValueArgs}" ${ARGN})

    string(REPLACE "/" "_" test_name "${test_file}")
    string(PREPEND test_name "EXPECT_FAIL.")
    add_executable(${test_name} EXCLUDE_FROM_ALL ${test_file})

    target_include_directories(${test_name} PRIVATE ${CF_INCLUDE_DIRECTORIES})
    target_link_libraries(${test_name} PRIVATE ${CF_LIBRARIES})
    target_link_libraries_system(${test_name} PRIVATE ${CF_SYSTEM_LIBRARIES})

    file(STRINGS ${test_file} pattern REGEX "// EXPECT: ")
    if(NOT pattern)
        set(pattern "(static_assert)|(static assertion failed)")
    else()
        string(REGEX REPLACE ".*// EXPECT: " "" pattern ${pattern})
    endif()

    add_test(NAME ${test_name}
             COMMAND ${CMAKE_COMMAND} --build ${CMAKE_BINARY_DIR} --target
                     ${test_name})
    set_tests_properties(${test_name} PROPERTIES PASS_REGULAR_EXPRESSION
                                                 "${pattern}")
endfunction()
