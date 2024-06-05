find_program(CLANG_FORMAT_PROGRAM "clang-format" HINTS ${CT_ROOT})
if(CLANG_FORMAT_PROGRAM)
    message(STATUS "clang-format found: ${CLANG_FORMAT_PROGRAM}")
endif()

add_versioned_package(
    NAME
    Format.cmake
    VERSION
    1.7.3
    GITHUB_REPOSITORY
    TheLartians/Format.cmake
    OPTIONS
    "CMAKE_FORMAT_EXCLUDE cmake/CPM.cmake")

add_dependencies(quality check-clang-format check-cmake-format)
add_dependencies(ci-quality check-clang-format check-cmake-format)
