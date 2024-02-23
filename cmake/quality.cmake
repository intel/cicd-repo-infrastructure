if(COMMAND clang_tidy_interface)
    return()
endif()

function(clang_tidy_interface)
    if(${ARGC} EQUAL 1)
        set(CT_TARGET ${ARGV0})
    else()
        cmake_parse_arguments(CT "" "TARGET" "" ${ARGN})
    endif()
    message(
        STATUS
            "clang_tidy_interface(${CT_TARGET}) is disabled because CMAKE_CXX_COMPILER_ID is ${CMAKE_CXX_COMPILER_ID}."
    )
endfunction()

if(PROJECT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
    get_filename_component(CT_ROOT ${CMAKE_CXX_COMPILER} DIRECTORY)
    find_program(CLANG_FORMAT_PROGRAM "clang-format" HINTS ${CT_ROOT})
    if(CLANG_FORMAT_PROGRAM)
        message(STATUS "clang-format found: ${CLANG_FORMAT_PROGRAM}")
    endif()

    include(${CMAKE_CURRENT_LIST_DIR}/sanitizers.cmake)
    include(${CMAKE_CURRENT_LIST_DIR}/test.cmake)
    include(${CMAKE_CURRENT_LIST_DIR}/warnings.cmake)
    include(${CMAKE_CURRENT_LIST_DIR}/profile.cmake)

    add_versioned_package(
        NAME
        Format.cmake
        VERSION
        1.7.3
        GITHUB_REPOSITORY
        TheLartians/Format.cmake
        OPTIONS
        "CMAKE_FORMAT_EXCLUDE cmake/CPM.cmake")

    add_custom_target(quality)
    add_custom_target(ci-quality)
    add_dependencies(quality check-clang-format check-cmake-format)
    add_dependencies(ci-quality check-clang-format check-cmake-format)

    if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        find_program(CLANG_TIDY_PROGRAM "clang-tidy" HINTS ${CT_ROOT})
        if(CLANG_TIDY_PROGRAM)
            message(STATUS "clang-tidy found at ${CLANG_TIDY_PROGRAM}.")
            add_custom_target(clang-tidy)
            add_custom_target(clang-tidy-branch-diff)
            include(${CMAKE_CURRENT_LIST_DIR}/clang-tidy.cmake)
        else()
            message(STATUS "clang-tidy not found. Adding dummy target.")
            set(CLANG_TIDY_NOT_FOUND_COMMAND_ARGS
                COMMAND ${CMAKE_COMMAND} -E echo
                "Cannot run clang-tidy because clang-tidy not found." COMMAND
                ${CMAKE_COMMAND} -E false)
            add_custom_target(clang-tidy ${CLANG_TIDY_NOT_FOUND_COMMAND_ARGS})
            add_custom_target(clang-tidy-branch-diff
                              ${CLANG_TIDY_NOT_FOUND_COMMAND_ARGS})
        endif()
        add_dependencies(quality clang-tidy)
        add_dependencies(ci-quality clang-tidy-branch-diff)
    endif()
endif()
