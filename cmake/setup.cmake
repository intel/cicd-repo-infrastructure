if(COMMAND make_gitignore)
    return()
endif()

function(make_gitignore)
    set(GITIGNORE_CONTENTS
        "/build"
        "/cmake-build-*"
        "/venv"
        "/.vscode"
        "/.idea"
        "/.cache"
        "/.DS_Store")

    if(NOT EXISTS "${CMAKE_SOURCE_DIR}/.clang-format")
        list(APPEND GITIGNORE_CONTENTS ".clang-format")
    endif()
    if(NOT EXISTS "${CMAKE_SOURCE_DIR}/.clang-tidy")
        list(APPEND GITIGNORE_CONTENTS ".clang-tidy")
    endif()
    if(NOT EXISTS "${CMAKE_SOURCE_DIR}/.cmake-format.yaml")
        list(APPEND GITIGNORE_CONTENTS ".cmake-format.yaml")
    endif()
    if(NOT EXISTS "${CMAKE_SOURCE_DIR}/CMakePresets.json")
        list(APPEND GITIGNORE_CONTENTS "CMakePresets.json")
    endif()
    if(NOT EXISTS "${CMAKE_SOURCE_DIR}/toolchains")
        list(APPEND GITIGNORE_CONTENTS "/toolchains")
    endif()

    string(REPLACE ";" "\n" GITIGNORE_CONTENTS "${GITIGNORE_CONTENTS}")

    if(NOT EXISTS "${CMAKE_SOURCE_DIR}/.gitignore")
        execute_process(COMMAND ${CMAKE_COMMAND} -E echo ${GITIGNORE_CONTENTS}
                        OUTPUT_FILE "${CMAKE_SOURCE_DIR}/.gitignore")
    endif()
endfunction()

function(make_symlink_in_project_dir FILENAME)
    if(NOT EXISTS "${CMAKE_SOURCE_DIR}/${FILENAME}")
        execute_process(
            COMMAND
                ${CMAKE_COMMAND} -E create_symlink
                "${CMAKE_CURRENT_SOURCE_DIR}/${FILENAME}"
                "${CMAKE_SOURCE_DIR}/${FILENAME}")
    endif()
endfunction()

if(PROJECT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
    make_gitignore()

    make_symlink_in_project_dir(".clang-format")
    make_symlink_in_project_dir(".clang-tidy")
    make_symlink_in_project_dir(".cmake-format.yaml")
    make_symlink_in_project_dir("CMakePresets.json")
    make_symlink_in_project_dir("toolchains")

    execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory
                            "${CMAKE_SOURCE_DIR}/.github/workflows")
    file(COPY "${CMAKE_CURRENT_SOURCE_DIR}/ci/.github/workflows/unit_tests.yml"
         DESTINATION "${CMAKE_SOURCE_DIR}/.github/workflows")
    file(
        COPY "${CMAKE_CURRENT_SOURCE_DIR}/ci/.github/workflows/asciidoctor-ghpages.yml"
        DESTINATION "${CMAKE_SOURCE_DIR}/.github/workflows")
endif()
