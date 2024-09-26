add_custom_target(mull_tests)

function(add_mull_test name)
    message(
        STATUS
            "add_mull_test(${name}) is disabled because CMAKE_CXX_COMPILER_ID is ${CMAKE_CXX_COMPILER_ID}."
    )
endfunction()

if(NOT CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    return()
endif()

function(find_mull)
    string(REGEX MATCH "[0-9]+" version ${CMAKE_CXX_COMPILER_VERSION})
    find_program(MULL_RUNNER_PROGRAM "mull-runner-${version}")
    if(MULL_RUNNER_PROGRAM)
        message(
            STATUS "mull-runner-${version} found at ${MULL_RUNNER_PROGRAM}.")
    else()
        message(
            STATUS
                "mull-runner-${version} not found. add_mull_test() will fail unless a valid RUNNER_DIR is provided."
        )
    endif()
    find_file(MULL_PLUGIN_LIBRARY "mull-ir-frontend-${version}"
              HINTS "/usr/lib")
    if(MULL_PLUGIN_LIBRARY)
        message(
            STATUS
                "mull-ir-frontend-${version} found at ${MULL_PLUGIN_LIBRARY}.")
    else()
        message(
            STATUS
                "mull-ir-frontend-${version} not found. add_mull_test() will fail unless a valid PLUGIN_DIR is provided."
        )
    endif()
    return(PROPAGATE MULL_RUNNER_PROGRAM MULL_PLUGIN_LIBRARY)
endfunction()

find_mull()

function(add_mull_test name)
    set(options EXCLUDE_CTEST)
    set(singleValueArgs PLUGIN_DIR RUNNER_DIR)
    set(multiValueArgs RUNNER_ARGS)
    cmake_parse_arguments(MULL "${options}" "${singleValueArgs}"
                          "${multiValueArgs}" ${ARGN})

    string(REGEX MATCH "[0-9]+" version ${CMAKE_CXX_COMPILER_VERSION})

    set(MULL_RUNNER_NOT_FOUND_COMMAND
        COMMAND ${CMAKE_COMMAND} -E echo
        "Cannot run mull_${name} because mull-runner-${version} not found."
        COMMAND ${CMAKE_COMMAND} -E false)
    set(MULL_PLUGIN_NOT_FOUND_COMMAND
        COMMAND ${CMAKE_COMMAND} -E echo
        "Cannot build mull_${name} because mull-ir-frontend-${version} not found."
        COMMAND ${CMAKE_COMMAND} -E false)

    if(MULL_RUNNER_DIR)
        find_program(MULL_RUNNER "mull-runner-${version}"
                     HINTS ${MULL_RUNNER_DIR})
    else()
        set(MULL_RUNNER ${MULL_RUNNER_PROGRAM})
        set(MULL_RUNNER_DIR "<RUNNER_DIR not provided>")
    endif()
    if(NOT MULL_RUNNER)
        message(
            WARNING
                "mull-runner-${version} not found at ${MULL_RUNNER_DIR}. mull_${name} is a failing test."
        )
        add_custom_target(mull_${name} ${MULL_RUNNER_NOT_FOUND_COMMAND})
        add_dependencies(mull_tests mull_${name})
        return()
    endif()

    if(MULL_PLUGIN_DIR)
        find_file(MULL_PLUGIN "mull-ir-frontend-${version}"
                  HINTS ${MULL_PLUGIN_DIR})
    else()
        set(MULL_PLUGIN ${MULL_PLUGIN_LIBRARY})
        set(MULL_PLUGIN_DIR "<PLUGIN_DIR not provided>")
    endif()
    if(NOT MULL_PLUGIN)
        message(
            WARNING
                "mull-ir-frontend-${version} not found at ${MULL_PLUGIN_DIR}. mull_${name} is a failing test."
        )
        add_custom_target(mull_${name} ${MULL_PLUGIN_NOT_FOUND_COMMAND})
        add_dependencies(mull_tests mull_${name})
        return()
    endif()

    target_compile_options(${name} PRIVATE -fpass-plugin=${MULL_PLUGIN} -O0 -g
                                           -grecord-command-line)
    target_link_libraries(${name} PRIVATE coverage)

    set(mull_test_command $<TARGET_FILE:${name}>)
    add_custom_target(mull_${name} DEPENDS ${name}.mull)
    add_custom_command(
        OUTPUT ${name}.mull
        COMMAND ${MULL_RUNNER} ${MULL_RUNNER_ARGS} ${mull_test_command}
        COMMAND ${CMAKE_COMMAND} "-E" "touch" "${name}.mull"
        DEPENDS ${name}
        COMMAND_EXPAND_LISTS)

    if(NOT MULL_EXCLUDE_CTEST)
        add_test(NAME MULL.${name}
                 COMMAND ${MULL_RUNNER} ${MULL_RUNNER_ARGS}
                         ${mull_test_command} COMMAND_EXPAND_LISTS)
    endif()

    add_dependencies(mull_tests mull_${name})
endfunction()
