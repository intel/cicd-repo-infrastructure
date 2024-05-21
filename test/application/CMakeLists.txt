cmake_minimum_required(VERSION 3.20)
project(test_app)

include(cmake/get_cpm.cmake)
cpmaddpackage(NAME infra SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../.." GIT_TAG
              HEAD)

add_versioned_package(NAME test_lib SOURCE_DIR
                      "${CMAKE_CURRENT_SOURCE_DIR}/../library" GIT_TAG HEAD)

add_executable(test_app src/test.cpp)
target_link_libraries(test_app PRIVATE test_lib)

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    add_subdirectory(test)
    add_subdirectory(recipes)
endif()
