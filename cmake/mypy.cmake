function(mypy_lint)
    message(STATUS "mypy_lint(...) is disabled because mypy was not found.")
endfunction()

find_program(MYPY_PROGRAM "mypy")
if(MYPY_PROGRAM)
    message(STATUS "mypy found at ${MYPY_PROGRAM}")
    add_custom_target(mypy-lint)
    add_custom_target(mypy-lint-branch-diff)
    add_dependencies(quality mypy-lint)
    add_dependencies(ci-quality mypy-lint-branch-diff)
else()
    message(STATUS "mypy not found. Adding dummy target.")
    set(MYPY_NOT_FOUND_COMMAND_ARGS
        COMMAND ${CMAKE_COMMAND} -E echo
        "Cannot run mypy because mypy not found." COMMAND ${CMAKE_COMMAND} -E
        false)
    add_custom_target(mypy-lint ${MYPY_NOT_FOUND_COMMAND_ARGS})
    add_custom_target(mypy-lint-branch-diff ${MYPY_NOT_FOUND_COMMAND_ARGS})
    return()
endif()

function(mypy_lint)
    set(options "")
    set(oneValueArgs "")
    set(multiValueArgs FILES OPTIONS)
    cmake_parse_arguments(ML "${options}" "${oneValueArgs}" "${multiValueArgs}"
                          ${ARGN})

    foreach(file ${ML_FILES})
        file(REAL_PATH ${file} file)
        filename_to_target(${file} target "mypy-lint_")
        set(artifact "${CMAKE_CURRENT_BINARY_DIR}/${target}.linted")

        add_custom_target(${target} DEPENDS ${artifact})
        add_custom_command(
            OUTPUT ${artifact}
            COMMAND ${MYPY_PROGRAM} --ignore-missing-imports ${ML_OPTIONS}
                    ${file}
            COMMAND ${CMAKE_COMMAND} "-E" "touch" ${artifact}
            DEPENDS ${file}
            COMMAND_EXPAND_LISTS
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
        add_dependencies(mypy-lint ${target})
    endforeach()

    compute_branch_diff(mypy-lint ".py")
endfunction()
