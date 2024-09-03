cmake_minimum_required(VERSION 3.20)
project(test_lib)

include(cmake/get_cpm.cmake)
cpmaddpackage(NAME infra SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../.." GIT_TAG
              HEAD)

add_library(test_lib INTERFACE)
target_compile_features(test_lib INTERFACE cxx_std_20)
target_sources(
    test_lib
    INTERFACE FILE_SET
              test_lib
              TYPE
              HEADERS
              BASE_DIRS
              include
              FILES
              include/test_lib/test.hpp)
target_sources(
    test_lib
    INTERFACE FILE_SET
              exclusions
              TYPE
              HEADERS
              BASE_DIRS
              include
              FILES
              include/test_lib/exclude.hpp
              include/exclude/bad.hpp)

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    add_docs(docs)
    clang_tidy_interface(TARGET test_lib EXCLUDE_FILESETS exclusions)
endif()
