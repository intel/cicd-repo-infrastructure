if(COMMAND add_docs)
    return()
endif()

if(NOT PROJECT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
    return()
endif()

if(DEFINED ENV{ASCIIDOCTOR_PATH})
    list(PREPEND CMAKE_PROGRAM_PATH $ENV{ASCIIDOCTOR_PATH})
endif()

function(add_docs DIRECTORY)
    message(
        STATUS
            "add_docs(${DIRECTORY}) is disabled because asciidoctor was not found."
    )
endfunction()

find_program(ASCIIDOCTOR_PROGRAM "asciidoctor")
if(ASCIIDOCTOR_PROGRAM)
    message(STATUS "asciidoctor found at ${ASCIIDOCTOR_PROGRAM}.")
    add_custom_target(docs ALL)
else()
    message(STATUS "asciidoctor not found. Adding dummy target.")
    set(ASCIIDOCTOR_NOT_FOUND_COMMAND_ARGS
        COMMAND ${CMAKE_COMMAND} -E echo
        "Cannot run asciidoctor because asciidoctor not found." COMMAND
        ${CMAKE_COMMAND} -E false)
    add_custom_target(docs ${ASCIIDOCTOR_NOT_FOUND_COMMAND_ARGS})
    return()
endif()

function(add_docs DIRECTORY)
    add_custom_target(
        docs_${DIRECTORY} DEPENDS ${CMAKE_BINARY_DIR}/${DIRECTORY}/index.html
                                  ${CMAKE_BINARY_DIR}/${DIRECTORY}/static)
    if(EXISTS ${CMAKE_SOURCE_DIR}/${DIRECTORY}/static)
        add_custom_command(
            OUTPUT ${CMAKE_BINARY_DIR}/${DIRECTORY}/static
            COMMAND
                ${CMAKE_COMMAND} -E copy_directory
                ${CMAKE_SOURCE_DIR}/${DIRECTORY}/static
                ${CMAKE_BINARY_DIR}/${DIRECTORY}/static
            DEPENDS ${CMAKE_SOURCE_DIR}/${DIRECTORY}/static)
    else()
        add_custom_command(
            OUTPUT ${CMAKE_BINARY_DIR}/${DIRECTORY}/static
            COMMAND ${CMAKE_COMMAND} -E make_directory
                    ${CMAKE_BINARY_DIR}/${DIRECTORY}/static)
    endif()

    file(GLOB_RECURSE doc_files ${CMAKE_SOURCE_DIR}/${DIRECTORY}/*.adoc)
    add_custom_command(
        OUTPUT ${CMAKE_BINARY_DIR}/${DIRECTORY}/index.html
        COMMAND
            ${ASCIIDOCTOR_PROGRAM} -r asciidoctor-diagram
            ${CMAKE_SOURCE_DIR}/${DIRECTORY}/index.adoc -D
            ${CMAKE_BINARY_DIR}/${DIRECTORY}
        DEPENDS ${doc_files})
    add_dependencies(docs docs_${DIRECTORY})
endfunction()
