set(CREATE_CLANG_TIDIABLE_SCRIPT
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/create-clang-tidiable.sh"
    CACHE STRING "" FORCE)

function(clang_tidy_header HEADER TARGET)
    file(RELATIVE_PATH CT_NAME ${CMAKE_SOURCE_DIR} ${HEADER})
    string(REPLACE "/" "_" CT_NAME ${CT_NAME})
    get_filename_component(CT_NAME ${CT_NAME} NAME_WLE)
    set(CT_NAME "clang-tidy_${CT_NAME}")
    set(CPP_NAME
        "${CMAKE_BINARY_DIR}/generated-sources/${TARGET}/${CT_NAME}.cpp")

    add_custom_command(
        OUTPUT "${CPP_NAME}"
        COMMAND ${CMAKE_COMMAND} -E make_directory
                "${CMAKE_BINARY_DIR}/generated-sources/${TARGET}"
        COMMAND "${CREATE_CLANG_TIDIABLE_SCRIPT}" ${CPP_NAME} ${HEADER}
        DEPENDS ${HEADER} ${CMAKE_SOURCE_DIR}/.clang-tidy)

    add_library(${CT_NAME} EXCLUDE_FROM_ALL ${CPP_NAME})
    target_link_libraries(${CT_NAME} PRIVATE ${TARGET})
    set_target_properties(
        ${CT_NAME}
        PROPERTIES
            CXX_CLANG_TIDY
            "${CLANG_TIDY_PROGRAM};-p;${CMAKE_BINARY_DIR};-header-filter=${HEADER}"
    )

    add_dependencies(clang-tidy "${CT_NAME}")
endfunction()

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

function(compute_clang_tidy_branch_diff)
    if(NOT DEFINED ENV{PR_TARGET_BRANCH})
        return()
    endif()
    get_target_property(ct_deps clang-tidy MANUALLY_ADDED_DEPENDENCIES)
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
        list(TRANSFORM changed_files REPLACE "/" "_" OUTPUT_VARIABLE
                                                     changed_files)
        list(TRANSFORM changed_files PREPEND "clang-tidy_" OUTPUT_VARIABLE
                                                           changed_files)
        list(TRANSFORM changed_files REPLACE "\.hpp" "" OUTPUT_VARIABLE
                                                        changed_targets)
        set_intersection(diff_targets SET1 ${ct_deps} SET2 ${changed_targets})
        foreach(diff ${diff_targets})
            add_dependencies(clang-tidy-branch-diff "${diff}")
        endforeach()
    endif()
endfunction()

function(clang_tidy_interface)
    if(${ARGC} EQUAL 1)
        set(CT_TARGET ${ARGV0})
    else()
        set(options "")
        set(oneValueArgs TARGET)
        set(multiValueArgs EXCLUDE_DIRS EXCLUDE_FILES)
        cmake_parse_arguments(CT "${options}" "${oneValueArgs}"
                              "${multiValueArgs}" ${ARGN})
    endif()

    get_target_property(DIRS ${CT_TARGET} INTERFACE_INCLUDE_DIRECTORIES)
    get_target_property(SYSTEM_DIRS ${CT_TARGET}
                        INTERFACE_SYSTEM_INCLUDE_DIRECTORIES)
    foreach(DIR ${DIRS})
        if(NOT DIR IN_LIST SYSTEM_DIRS)
            file(GLOB_RECURSE HEADERS "${DIR}/*.hpp")
            foreach(HEADER ${HEADERS})
                file(RELATIVE_PATH CT_NAME ${CMAKE_SOURCE_DIR} ${HEADER})
                if(NOT CT_NAME IN_LIST CT_EXCLUDE_FILES)
                    get_filename_component(HEADER_DIR ${CT_NAME} DIRECTORY)
                    if(NOT HEADER_DIR IN_LIST CT_EXCLUDE_DIRS)
                        clang_tidy_header(${HEADER} ${CT_TARGET})
                    endif()
                endif()
            endforeach()
        endif()
    endforeach()

    compute_clang_tidy_branch_diff()
endfunction()
