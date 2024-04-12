function(set_union output)
    list(APPEND u ${ARGN})
    list(REMOVE_DUPLICATES u)
    set(${output}
        ${u}
        PARENT_SCOPE)
endfunction()

function(set_difference output)
    set(multiValueArgs SET1 SET2)
    cmake_parse_arguments("" "" "" "${multiValueArgs}" ${ARGN})
    list(APPEND d ${_SET1})
    list(REMOVE_ITEM d ${_SET2})
    set(${output}
        ${d}
        PARENT_SCOPE)
endfunction()

function(set_symmetric_difference output)
    set(multiValueArgs SET1 SET2)
    cmake_parse_arguments("" "" "" "${multiValueArgs}" ${ARGN})
    set_difference(d1 SET1 ${_SET1} SET2 ${_SET2})
    set_difference(d2 SET1 ${_SET2} SET2 ${_SET1})
    set_union(u ${d1} ${d2})
    set(${output}
        ${u}
        PARENT_SCOPE)
endfunction()

function(set_intersection output)
    set(multiValueArgs SET1 SET2)
    cmake_parse_arguments("" "" "" "${multiValueArgs}" ${ARGN})
    set_symmetric_difference(sd SET1 ${_SET1} SET2 ${_SET2})
    set_union(u ${_SET1} ${_SET2})
    set_difference(d SET1 ${u} SET2 ${sd})
    set(${output}
        ${d}
        PARENT_SCOPE)
endfunction()

function(filename_to_target filename output prefix)
    get_filename_component(ext ${filename} LAST_EXT)
    file(RELATIVE_PATH target ${CMAKE_SOURCE_DIR} ${filename})
    string(REPLACE "/" "_" target ${target})
    string(REGEX REPLACE "${ext}$" "" target ${target})
    set(target "${prefix}${target}")
    set(${output}
        ${target}
        PARENT_SCOPE)
endfunction()

function(compute_branch_diff TARGET EXTENSION)
    if(NOT DEFINED ENV{PR_TARGET_BRANCH})
        return()
    endif()
    get_target_property(ct_deps ${TARGET} MANUALLY_ADDED_DEPENDENCIES)
    execute_process(
        COMMAND git rev-parse --show-prefix
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE prefix
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    execute_process(
        COMMAND git diff-tree --no-commit-id --name-only --diff-filter=AMR -r
                HEAD $ENV{PR_TARGET_BRANCH}
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE changed_files
        OUTPUT_STRIP_TRAILING_WHITESPACE)

    if(changed_files)
        string(REPLACE "\n" ";" changed_files ${changed_files})
        if(prefix)
            list(TRANSFORM changed_files REPLACE "^${prefix}" "" OUTPUT_VARIABLE
                                                                 changed_files)
        endif()

        foreach(file ${changed_files})
            file(REAL_PATH ${file} file BASE_DIRECTORY ${CMAKE_SOURCE_DIR})
            get_filename_component(ext ${file} LAST_EXT)
            if(EXTENSION STREQUAL ext)
                filename_to_target(${file} file "${TARGET}_")
                string(REGEX REPLACE "${ext}$" "" file ${file})
                list(APPEND changed_targets ${file})
            endif()
        endforeach()

        set_intersection(diff_targets SET1 ${ct_deps} SET2 ${changed_targets})
        foreach(diff ${diff_targets})
            add_dependencies("${TARGET}-branch-diff" "${diff}")
        endforeach()
    endif()
endfunction()
