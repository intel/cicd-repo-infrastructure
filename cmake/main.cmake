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
    set(CMAKE_CXX_STANDARD
        20
        CACHE INTERNAL "" FORCE)
endif()

set(CMAKE_EXPORT_COMPILE_COMMANDS
    ON
    CACHE BOOL "Export compile commands to compile_commands.json." FORCE)

option(INFRA_PROVIDE_GITHUB_WORKFLOWS
       "Provide unit_test and documentation workflows" ON)
option(INFRA_PROVIDE_CLANG_FORMAT "Provide .clang-format file" ON)
option(INFRA_PROVIDE_CLANG_TIDY "Provide .clang-tidy file" ON)
option(INFRA_PROVIDE_CMAKE_FORMAT "Provide .cmake-format.yaml file" ON)
option(INFRA_PROVIDE_PRESETS "Provide cmake presets and toolchains" ON)
option(INFRA_PROVIDE_MULL "Provide mull.yml file" ON)
option(INFRA_PROVIDE_GITIGNORE "Add provided things to .gitignore" ON)
option(INFRA_USE_SYMLINKS "Use symlinks to provide common files" ON)

if(${PROJECT_SOURCE_DIR}/cmake STREQUAL CMAKE_CURRENT_LIST_DIR)
    set(INFRA_PROVIDE_GITHUB_WORKFLOWS OFF)
    set(INFRA_PROVIDE_CLANG_FORMAT OFF)
    set(INFRA_PROVIDE_CLANG_TIDY OFF)
    set(INFRA_PROVIDE_CMAKE_FORMAT OFF)
    set(INFRA_PROVIDE_PRESETS OFF)
    set(INFRA_PROVIDE_MULL OFF)
    set(INFRA_PROVIDE_GITIGNORE OFF)
endif()

include(${CMAKE_CURRENT_LIST_DIR}/cpm_recipes.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/dependencies.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/libraries.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/setup.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/quality.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/docs.cmake)

if(${PROJECT_SOURCE_DIR}/cmake STREQUAL CMAKE_CURRENT_LIST_DIR)
    add_docs(${CMAKE_CURRENT_LIST_DIR}/../docs)
endif()
