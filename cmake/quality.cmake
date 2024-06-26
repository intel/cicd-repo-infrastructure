if(TARGET quality)
    return()
endif()

if(PROJECT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
    add_custom_target(quality)
    add_custom_target(ci-quality)

    get_filename_component(CT_ROOT ${CMAKE_CXX_COMPILER} DIRECTORY)

    include(${CMAKE_CURRENT_LIST_DIR}/branch_diff.cmake)

    include(${CMAKE_CURRENT_LIST_DIR}/sanitizers.cmake)
    include(${CMAKE_CURRENT_LIST_DIR}/test.cmake)
    include(${CMAKE_CURRENT_LIST_DIR}/benchmark.cmake)

    include(${CMAKE_CURRENT_LIST_DIR}/warnings.cmake)
    include(${CMAKE_CURRENT_LIST_DIR}/profile.cmake)
    include(${CMAKE_CURRENT_LIST_DIR}/diagnostics.cmake)
    include(${CMAKE_CURRENT_LIST_DIR}/coverage.cmake)

    include(${CMAKE_CURRENT_LIST_DIR}/format.cmake)
    include(${CMAKE_CURRENT_LIST_DIR}/clang-tidy.cmake)
    include(${CMAKE_CURRENT_LIST_DIR}/mypy.cmake)
    include(${CMAKE_CURRENT_LIST_DIR}/black.cmake)
endif()
