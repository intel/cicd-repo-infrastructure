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

if(NOT CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    return()
endif()

find_program(CLANG_TIDY_PROGRAM "clang-tidy" HINTS ${CT_ROOT})
if(CLANG_TIDY_PROGRAM)
    message(STATUS "clang-tidy found at ${CLANG_TIDY_PROGRAM}.")
    add_custom_target(clang-tidy)
    add_custom_target(clang-tidy-branch-diff)
    add_dependencies(quality clang-tidy)
    add_dependencies(ci-quality clang-tidy-branch-diff)
else()
    message(STATUS "clang-tidy not found. Adding dummy target.")
    set(CLANG_TIDY_NOT_FOUND_COMMAND_ARGS
        COMMAND ${CMAKE_COMMAND} -E echo
        "Cannot run clang-tidy because clang-tidy not found." COMMAND
        ${CMAKE_COMMAND} -E false)
    add_custom_target(clang-tidy ${CLANG_TIDY_NOT_FOUND_COMMAND_ARGS})
    add_custom_target(clang-tidy-branch-diff
                      ${CLANG_TIDY_NOT_FOUND_COMMAND_ARGS})
    return()
endif()

set(CREATE_CLANG_TIDIABLE_SCRIPT
    "${CMAKE_CURRENT_LIST_DIR}/scripts/create-clang-tidiable.sh"
    CACHE STRING "" FORCE)

function(clang_tidy_header HEADER TARGET)
    filename_to_target(${HEADER} CT_NAME "clang-tidy_")
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

function(clang_tidy_dirs TARGET EXCLUDE_DIRS EXCLUDE_FILES)
    get_target_property(DIRS ${TARGET} INTERFACE_INCLUDE_DIRECTORIES)
    get_target_property(SYSTEM_DIRS ${TARGET}
                        INTERFACE_SYSTEM_INCLUDE_DIRECTORIES)
    foreach(DIR ${DIRS})
        if(NOT DIR IN_LIST SYSTEM_DIRS)
            file(GLOB_RECURSE HEADERS "${DIR}/*.hpp")
            foreach(HEADER ${HEADERS})
                file(RELATIVE_PATH CT_NAME ${CMAKE_SOURCE_DIR} ${HEADER})
                if(NOT CT_NAME IN_LIST EXCLUDE_FILES)
                    get_filename_component(HEADER_DIR ${CT_NAME} DIRECTORY)
                    if(NOT HEADER_DIR IN_LIST EXCLUDE_DIRS)
                        clang_tidy_header(${HEADER} ${TARGET})
                    endif()
                endif()
            endforeach()
        endif()
    endforeach()
endfunction()

function(clang_tidy_header_sets TARGET EXCLUDE_DIRS EXCLUDE_FILES
         EXCLUDE_FILESETS)
    get_target_property(HEADER_SETS ${TARGET} INTERFACE_HEADER_SETS)
    foreach(SET ${HEADER_SETS})
        if(NOT SET IN_LIST EXCLUDE_FILESETS)
            get_target_property(HEADERS ${TARGET} HEADER_SET_${SET})
            foreach(HEADER ${HEADERS})
                file(RELATIVE_PATH CT_NAME ${CMAKE_SOURCE_DIR} ${HEADER})
                if(NOT CT_NAME IN_LIST EXCLUDE_FILES)
                    get_filename_component(HEADER_DIR ${CT_NAME} DIRECTORY)
                    if(NOT HEADER_DIR IN_LIST EXCLUDE_DIRS)
                        clang_tidy_header(${HEADER} ${TARGET})
                    endif()
                endif()
            endforeach()
        endif()
    endforeach()
endfunction()

function(clang_tidy_interface)
    if(${ARGC} EQUAL 1)
        set(CT_TARGET ${ARGV0})
    else()
        set(options "")
        set(oneValueArgs TARGET)
        set(multiValueArgs EXCLUDE_DIRS EXCLUDE_FILES EXCLUDE_FILESETS)
        cmake_parse_arguments(CT "${options}" "${oneValueArgs}"
                              "${multiValueArgs}" ${ARGN})
    endif()

    get_target_property(HEADER_SETS ${CT_TARGET} INTERFACE_HEADER_SETS)
    if(HEADER_SETS)
        message(
            STATUS "Using INTERFACE_HEADER_SETS to clang-tidy ${CT_TARGET}.")
        clang_tidy_header_sets(${CT_TARGET} "${CT_EXCLUDE_DIRS}"
                               "${CT_EXCLUDE_FILES}" "${CT_EXCLUDE_FILESETS}")
    else()
        message(
            NOTICE
            "${CT_TARGET} has no INTERFACE_HEADER_SETS, using INTERFACE_INCLUDE_DIRECTORIES instead. "
            "Use `target_sources` instead of `target_include_directories` to specify header sets for better control."
        )
        clang_tidy_dirs(${CT_TARGET} "${CT_EXCLUDE_DIRS}" "${CT_EXCLUDE_FILES}")
    endif()

    compute_branch_diff(clang-tidy ".hpp")
endfunction()

if(NOT TARGET clang-tidy-canary)
    message(STATUS "Adding clang-tidy-canary target for ${CMAKE_SOURCE_DIR}")
    add_custom_command(
        OUTPUT clang_tidy_canary.alive
        COMMAND ${CLANG_TIDY_PROGRAM} "--verify-config" 2>clang_tidy.log
        COMMAND "!" "[" "-s" "clang_tidy.log" "]"
        COMMAND ${CMAKE_COMMAND} "-E" "touch" "clang_tidy_canary.alive"
        DEPENDS ${CMAKE_SOURCE_DIR}/.clang-tidy)
    add_custom_target(clang-tidy-canary DEPENDS clang_tidy_canary.alive)
    add_dependencies(clang-tidy clang-tidy-canary)
    add_dependencies(clang-tidy-branch-diff clang-tidy-canary)
endif()
