if(COMMAND add_versioned_package)
    return()
endif()

include(${CMAKE_CURRENT_LIST_DIR}/get_cpm.cmake)

if(NOT DEFINED ENV{CPM_SOURCE_CACHE})
    message(
        STATUS
            "The environment variable \$CPM_SOURCE_CACHE is not defined: defining a CPM cache is recommended to avoid extra downloads."
    )
endif()

function(check_version dep required comp)
    foreach(present ${ARGN})
        string(REGEX MATCH "[0-9]+(\.[0-9]+)*" req ${required})
        string(REGEX MATCH "[0-9]+(\.[0-9]+)*" pre ${present})
        string(REPLACE ${req} " " req_leftover ${required})
        string(REPLACE ${pre} " " pre_leftover ${present})
        if(${req_leftover} STREQUAL ${pre_leftover})
            if(pre VERSION_${comp} req)
                if(NOT pre VERSION_EQUAL req)
                    message(
                        STATUS
                            "Dependency: ${dep} required version ${version} (${comp}) is fulfilled by version ${present}."
                    )
                endif()
                return()
            endif()
        endif()
    endforeach()
    message(
        FATAL_ERROR
            "Dependency error for ${dep}: ${version} (${comp}) not fulfilled by one of: ${ARGN}."
    )
endfunction()

function(identify_git_tag dep tag is_tag)
    execute_process(
        COMMAND ${GIT_PROGRAM} tag -l ${tag}
        WORKING_DIRECTORY ${${dep}_SOURCE_DIR}
        OUTPUT_VARIABLE out_tag
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(out_tag STREQUAL tag)
        set(is_tag 1)
    else()
        set(is_tag 0)
    endif()
    return(PROPAGATE is_tag)
endfunction()

function(check_dependency_version dep version)
    if(${dep}_SOURCE_DIR)
        execute_process(
            COMMAND ${GIT_PROGRAM} rev-parse --short HEAD
            WORKING_DIRECTORY ${${dep}_SOURCE_DIR}
            OUTPUT_VARIABLE head_hash
            OUTPUT_STRIP_TRAILING_WHITESPACE)
        execute_process(
            COMMAND ${GIT_PROGRAM} tag -l --points-at ${head_hash}
            WORKING_DIRECTORY ${${dep}_SOURCE_DIR}
            OUTPUT_VARIABLE head_version
            OUTPUT_STRIP_TRAILING_WHITESPACE)
        if(head_version)
            string(REPLACE "\n" ";" head_version ${head_version})
        endif()

        set(comp EQUAL)
        if(${ARGC} GREATER 2)
            set(comp ${ARGV2})
        endif()

        identify_git_tag(${dep} ${version} is_tag)
        if(is_tag AND head_version)
            check_version(${dep} ${version} ${comp} ${head_version})
        else()
            execute_process(
                COMMAND ${GIT_PROGRAM} merge-base --is-ancestor ${version}
                        ${head_hash}
                WORKING_DIRECTORY ${${dep}_SOURCE_DIR}
                RESULT_VARIABLE hash_ok)
            if(hash_ok EQUAL 0)
                if(NOT head_hash STREQUAL version)
                    message(
                        STATUS
                            "Dependency: ${dep} required version ${version} is fulfilled by version ${head_hash}."
                    )
                endif()
            else()
                if(head_version)
                    check_version(${dep} ${version} ${comp} ${head_version})
                else()
                    message(
                        FATAL_ERROR
                            "Dependency error for ${dep}: ${version} is not an ancestor of ${head_hash}."
                    )
                endif()
            endif()
        endif()
    else()
        message(
            FATAL_ERROR
                "Missing required dependency: ${dep} at version ${version}.")
    endif()
endfunction()

if(NOT DEPS_INDENT)
    set(DEPS_INDENT
        "${CMAKE_PROJECT_NAME}"
        CACHE INTERNAL "")
    set(DEPS_DEPTH
        ""
        CACHE INTERNAL "")
endif()

option(
    LOG_CPM_DEPENDENCIES
    "Log CPM dependencies fetched with add_versioned_package to cpm_dependencies.txt"
    ON)

function(log_dependency_trail parent child depth)
    if(LOG_CPM_DEPENDENCIES)
        string(REPLACE "/" "_" parent_target ${parent})
        string(REPLACE "@" "_" parent_target ${parent_target})
        string(APPEND parent_target "_deps")

        set(DEPS_OUTPUT_FILE "${CMAKE_BINARY_DIR}/cpm_dependencies.txt")
        if(NOT TARGET deps_file)
            add_custom_target(deps_file)
            file(WRITE ${DEPS_OUTPUT_FILE} "")
        endif()

        if(NOT TARGET ${parent_target})
            add_custom_target(${parent_target})
            if(depth STREQUAL "")
                file(APPEND ${DEPS_OUTPUT_FILE} "${depth}${parent}\n")
            endif()
        endif()
        file(APPEND ${DEPS_OUTPUT_FILE} "${depth}└─ ${child}\n")
    endif()
endfunction()

function(add_versioned_package)
    list(LENGTH ARGN argnLength)
    if(argnLength EQUAL 1)
        cpm_parse_add_package_single_arg("${ARGN}" ARGN)
    endif()

    set(oneValueArgs NAME VERSION GITHUB_REPOSITORY GIT_TAG COMPARE)
    cmake_parse_arguments(ARGS "" "${oneValueArgs}" "" "${ARGN}")
    if(NOT DEFINED ARGS_GIT_TAG)
        set(ARGS_GIT_TAG v${ARGS_VERSION})
    endif()
    if(NOT DEFINED ARGS_COMPARE)
        set(ARGS_COMPARE GREATER_EQUAL)
    endif()
    if(NOT DEFINED ARGS_NAME)
        set(ARGS_NAME ${ARGS_GITHUB_REPOSITORY})
    endif()

    set(DEPS_PARENT_INDENT "${DEPS_INDENT}")
    set(DEPS_INDENT "${ARGS_NAME}@${ARGS_GIT_TAG}")
    log_dependency_trail(${DEPS_PARENT_INDENT} ${DEPS_INDENT} "${DEPS_DEPTH}")
    string(APPEND DEPS_DEPTH "   ")
    cpmaddpackage("${ARGN}")
    string(REGEX REPLACE "^(.*)...$" "\\1" DEPS_DEPTH ${DEPS_DEPTH})
    set(DEPS_INDENT "${DEPS_PARENT_INDENT}")

    check_dependency_version(${CPM_LAST_PACKAGE_NAME} ${ARGS_GIT_TAG}
                             ${ARGS_COMPARE})

    set(CPM_LAST_PACKAGE_NAME
        ${CPM_LAST_PACKAGE_NAME}
        PARENT_SCOPE)
    set(${CPM_LAST_PACKAGE_NAME}_SOURCE_DIR
        ${${CPM_LAST_PACKAGE_NAME}_SOURCE_DIR}
        PARENT_SCOPE)
    set(${CPM_LAST_PACKAGE_NAME}_BINARY_DIR
        ${${CPM_LAST_PACKAGE_NAME}_BINARY_DIR}
        PARENT_SCOPE)
    set(${CPM_LAST_PACKAGE_NAME}_ADDED
        ${${CPM_LAST_PACKAGE_NAME}_ADDED}
        PARENT_SCOPE)
endfunction()

function(update_versioned_package)
    list(LENGTH ARGN argnLength)
    if(argnLength EQUAL 1)
        cpm_parse_add_package_single_arg("${ARGN}" ARGN)
    endif()

    set(oneValueArgs NAME GITHUB_REPOSITORY GIT_TAG)
    cmake_parse_arguments(ARGS "" "${oneValueArgs}" "" "${ARGN}")

    if(NOT DEFINED ARGS_GIT_TAG)
        set(ARGS_GIT_TAG v${ARGS_VERSION})
    endif()
    set(GIT_URI "https://github.com/${ARGS_GITHUB_REPOSITORY}.git")
    if(NOT DEFINED ARGS_NAME)
        cpm_package_name_from_git_uri(${GIT_URI} ARGS_NAME)
    endif()

    set(pkg_dir ${${ARGS_NAME}_SOURCE_DIR})
    execute_process(
        COMMAND ${GIT_PROGRAM} ls-remote -h ${GIT_URI} ${ARGS_GIT_TAG}
        WORKING_DIRECTORY ${pkg_dir}
        OUTPUT_VARIABLE remote_hash
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    string(REGEX REPLACE "\t.*" "" remote_hash ${remote_hash})

    execute_process(
        COMMAND ${GIT_PROGRAM} rev-parse HEAD
        WORKING_DIRECTORY ${pkg_dir}
        OUTPUT_VARIABLE head_hash
        OUTPUT_STRIP_TRAILING_WHITESPACE)

    if(NOT head_hash STREQUAL remote_hash)
        message(
            STATUS
                "update_versioned_package: ${ARGS_NAME} is not at latest ${ARGS_GIT_TAG} -- updating."
        )
        execute_process(COMMAND ${GIT_PROGRAM} fetch origin
                        WORKING_DIRECTORY ${pkg_dir})
        execute_process(
            COMMAND ${GIT_PROGRAM} reset --hard "origin/${ARGS_GIT_TAG}"
            WORKING_DIRECTORY ${pkg_dir}
            RESULT_VARIABLE reset_ok)
        if(NOT reset_ok EQUAL 0)
            message(
                FATAL
                "Couldn't update ${ARGS_NAME} to ${ARGS_GIT_TAG} - check the repository at ${pkg_dir}."
            )
        endif()
    else()
        message(
            STATUS
                "update_versioned_package: ${ARGS_NAME} is at ${ARGS_GIT_TAG} already."
        )
    endif()
endfunction()
