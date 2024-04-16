function(black_format)
    message(STATUS "black_format(...) is disabled because black was not found.")
endfunction()

find_program(BLACK_PROGRAM "black")
if(BLACK_PROGRAM)
    message(STATUS "black found at ${BLACK_PROGRAM}")
else()
    message(STATUS "black not found. Adding dummy target.")
    set(BLACK_NOT_FOUND_COMMAND_ARGS
        COMMAND ${CMAKE_COMMAND} -E echo
        "Cannot run black because black not found." COMMAND ${CMAKE_COMMAND} -E
        false)
    add_custom_target(check-black-format ${BLACK_NOT_FOUND_COMMAND_ARGS})
    add_custom_target(fix-black-format ${BLACK_NOT_FOUND_COMMAND_ARGS})
    return()
endif()

function(add_black_format_target name)
    execute_process(
        COMMAND ${GIT_PROGRAM} rev-parse --show-prefix
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE PREFIX
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    execute_process(
        COMMAND ${GIT_PROGRAM} rev-parse --show-toplevel
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE BASE_DIR
        OUTPUT_STRIP_TRAILING_WHITESPACE)

    add_custom_target(
        "${name}-black-format"
        COMMAND
            ${CMAKE_COMMAND} "-DGIT_PROGRAM=${GIT_PROGRAM}"
            "-DBLACK_PROGRAM=${BLACK_PROGRAM}" "-DFORMAT_FUNC=${name}"
            "-DWORKING_DIR=${BASE_DIR}/${PREFIX}" "-P"
            "${CMAKE_CURRENT_LIST_DIR}/scripts/black.cmake")
endfunction()

add_black_format_target("check")
add_black_format_target("fix")
add_dependencies(quality check-black-format)
add_dependencies(ci-quality check-black-format)
