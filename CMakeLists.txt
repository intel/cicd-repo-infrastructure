if(PROJECT_SOURCE_DIR STREQUAL PROJECT_BINARY_DIR)
    file(REMOVE "${PROJECT_SOURCE_DIR}/cpm-package-lock.cmake")
    file(REMOVE_RECURSE "${PROJECT_SOURCE_DIR}/_deps")
    file(REMOVE_RECURSE "${PROJECT_SOURCE_DIR}/CPM_modules")
    message(
        FATAL_ERROR
            "In-source builds are a bad idea. Please make a build directory instead. "
            "You should now remove the leftover files: CMakeCache.txt and CMakeFiles/."
    )
endif()

if(NOT DEFINED CMAKE_CXX_STANDARD)
    set(CMAKE_CXX_STANDARD 20)
endif()

set(CMAKE_EXPORT_COMPILE_COMMANDS
    ON
    CACHE BOOL "Export compile commands to compile_commands.json." FORCE)

include(cmake/cpm_recipes.cmake)
include(cmake/dependencies.cmake)
include(cmake/libraries.cmake)
include(cmake/setup.cmake)
include(cmake/quality.cmake)
include(cmake/docs.cmake)
