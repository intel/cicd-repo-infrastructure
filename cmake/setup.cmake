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
    else()
        message(
            "${CMAKE_SOURCE_DIR}/.gitignore exists, not overwriting -- this may result in git taking notice of symlinks"
        )
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

function(compare_and_update_file FILENAME SRC_DIR DST_DIR)
    if(NOT EXISTS "${DST_DIR}/${FILENAME}")
        file(COPY "${SRC_DIR}/${FILENAME}" DESTINATION "${DST_DIR}")
    else()
        execute_process(
            COMMAND ${CMAKE_COMMAND} -E compare_files "${SRC_DIR}/${FILENAME}"
                    "${DST_DIR}/${FILENAME}" RESULT_VARIABLE cmp)
        if(NOT cmp EQUAL 0)
            message(
                "${DST_DIR}/${FILENAME} is different from ${SRC_DIR}/${FILENAME}, updating"
            )
            file(COPY "${SRC_DIR}/${FILENAME}" DESTINATION "${DST_DIR}")
        endif()
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

    compare_and_update_file(
        unit_tests.yml "${CMAKE_CURRENT_SOURCE_DIR}/ci/.github/workflows"
        "${CMAKE_SOURCE_DIR}/.github/workflows")
    compare_and_update_file(
        asciidoctor-ghpages.yml
        "${CMAKE_CURRENT_SOURCE_DIR}/ci/.github/workflows"
        "${CMAKE_SOURCE_DIR}/.github/workflows")
    compare_and_update_file(
        dependabot.yml "${CMAKE_CURRENT_SOURCE_DIR}/ci/.github"
        "${CMAKE_SOURCE_DIR}/.github")
endif()
