cmake_minimum_required(VERSION 3.20)
project(test_app)

include(cmake/get_cpm.cmake)
cpmaddpackage(NAME infra SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../.." GIT_TAG
              HEAD)

fmt_recipe(10.2.1)
add_versioned_package(NAME test_lib SOURCE_DIR
                      "${CMAKE_CURRENT_SOURCE_DIR}/../library" GIT_TAG HEAD)

add_executable(test_app src/test.cpp)
target_link_libraries(test_app PRIVATE test_lib fmt::fmt-header-only)

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    add_subdirectory(test)
endif()
