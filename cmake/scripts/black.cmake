execute_process(
    COMMAND ${GIT_PROGRAM} ls-files --exclude-standard ${WORKING_DIR}
    WORKING_DIRECTORY ${WORKING_DIR}
    OUTPUT_VARIABLE all_files
    OUTPUT_STRIP_TRAILING_WHITESPACE)

string(REPLACE "\n" ";" all_files ${all_files})
list(TRANSFORM all_files PREPEND ${WORKING_DIR})
list(FILTER all_files INCLUDE REGEX "\\.py$")

foreach(f ${all_files})
    if(EXISTS ${f} AND NOT IS_DIRECTORY ${f})
        list(APPEND extant_files ${f})
    endif()
endforeach()

if(FORMAT_FUNC STREQUAL "fix")
    foreach(f ${extant_files})
        execute_process(COMMAND ${GIT_PROGRAM} diff --quiet ${f}
                        RESULT_VARIABLE result)
        if(NOT result)
            execute_process(COMMAND ${BLACK_PROGRAM} ${f})
        else()
            execute_process(COMMAND ${BLACK_PROGRAM} --check --quiet ${f}
                            RESULT_VARIABLE result)
            if(result)
                message(WARNING "${f} has unstaged changes; not reformatting")
            endif()
        endif()
    endforeach()
    return()
endif()

set(FORMATTED_FILE "${CMAKE_BINARY_DIR}/formatted.black")
foreach(f ${extant_files})
    execute_process(
        COMMAND ${BLACK_PROGRAM} -q -
        INPUT_FILE ${f}
        OUTPUT_FILE ${FORMATTED_FILE})

    execute_process(COMMAND ${GIT_PROGRAM} diff --quiet -G. --no-index -- ${f}
                            ${FORMATTED_FILE} RESULT_VARIABLE result)
    if(result)
        message(FATAL_ERROR "${f} needs to be reformatted ")
    endif()
endforeach()
