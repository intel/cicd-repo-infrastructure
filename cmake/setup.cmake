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

    if(INFRA_USE_SYMLINKS)
        if(INFRA_PROVIDE_CLANG_FORMAT)
            if(NOT EXISTS "${CMAKE_SOURCE_DIR}/.clang-format")
                list(APPEND GITIGNORE_CONTENTS ".clang-format")
            endif()
        endif()
        if(INFRA_PROVIDE_CLANG_TIDY)
            if(NOT EXISTS "${CMAKE_SOURCE_DIR}/.clang-tidy")
                list(APPEND GITIGNORE_CONTENTS ".clang-tidy")
            endif()
        endif()
        if(INFRA_PROVIDE_CMAKE_FORMAT)
            if(NOT EXISTS "${CMAKE_SOURCE_DIR}/.cmake-format.yaml")
                list(APPEND GITIGNORE_CONTENTS ".cmake-format.yaml")
            endif()
        endif()
        if(INFRA_PROVIDE_PRESETS)
            if(NOT EXISTS "${CMAKE_SOURCE_DIR}/CMakePresets.json")
                list(APPEND GITIGNORE_CONTENTS "CMakePresets.json")
            endif()
            if(NOT EXISTS "${CMAKE_SOURCE_DIR}/toolchains")
                list(APPEND GITIGNORE_CONTENTS "/toolchains")
            endif()
        endif()
        if(INFRA_PROVIDE_MULL)
            if(NOT EXISTS "${CMAKE_SOURCE_DIR}/mull.yml")
                list(APPEND GITIGNORE_CONTENTS "mull.yml")
            endif()
        endif()
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

function(put_in_project_dir FILENAME)
    if(INFRA_USE_SYMLINKS)
        set(put_command "create_symlink")
    else()
        set(put_command "copy")
    endif()
    if(NOT EXISTS "${CMAKE_SOURCE_DIR}/${FILENAME}")
        execute_process(
            COMMAND
                ${CMAKE_COMMAND} -E ${put_command}
                "${CMAKE_CURRENT_SOURCE_DIR}/${FILENAME}"
                "${CMAKE_SOURCE_DIR}/${FILENAME}")
    endif()
endfunction()

function(compare_and_update_file FILENAME SRC_DIR DST_DIR)
    set(options FORCE)
    cmake_parse_arguments(UPDATE "${options}" "" "" ${ARGN})

    if(NOT EXISTS "${DST_DIR}/${FILENAME}")
        file(COPY "${SRC_DIR}/${FILENAME}" DESTINATION "${DST_DIR}")
    elseif(UPDATE_FORCE)
        execute_process(
            COMMAND ${CMAKE_COMMAND} -E compare_files "${SRC_DIR}/${FILENAME}"
                    "${DST_DIR}/${FILENAME}" RESULT_VARIABLE cmp)
        if(NOT cmp EQUAL 0)
            message(
                "${DST_DIR}/${FILENAME} is different from ${SRC_DIR}/${FILENAME}, updating"
            )
            file(COPY "${SRC_DIR}/${FILENAME}" DESTINATION "${DST_DIR}")
        endif()
    else()
        message("${DST_DIR}/${FILENAME} exists, not updating")
    endif()
endfunction()

if(PROJECT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
    if(INFRA_PROVIDE_GITIGNORE)
        make_gitignore()
    endif()

    if(INFRA_PROVIDE_CLANG_FORMAT)
        put_in_project_dir(".clang-format")
    endif()
    if(INFRA_PROVIDE_CLANG_TIDY)
        put_in_project_dir(".clang-tidy")
    endif()
    if(INFRA_PROVIDE_CMAKE_FORMAT)
        put_in_project_dir(".cmake-format.yaml")
    endif()
    if(INFRA_PROVIDE_PRESETS)
        put_in_project_dir("CMakePresets.json")
        put_in_project_dir("toolchains")
    endif()
    if(INFRA_PROVIDE_MULL)
        put_in_project_dir("mull.yml")
    endif()

    if(INFRA_PROVIDE_GITHUB_WORKFLOWS)
        execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory
                                "${CMAKE_SOURCE_DIR}/.github/workflows")

        compare_and_update_file(
            unit_tests.yml "${CMAKE_CURRENT_SOURCE_DIR}/ci/.github/workflows"
            "${CMAKE_SOURCE_DIR}/.github/workflows")
        compare_and_update_file(
            asciidoctor-ghpages.yml
            "${CMAKE_CURRENT_SOURCE_DIR}/ci/.github/workflows"
            "${CMAKE_SOURCE_DIR}/.github/workflows" FORCE)
        compare_and_update_file(
            dependabot.yml "${CMAKE_CURRENT_SOURCE_DIR}/ci/.github"
            "${CMAKE_SOURCE_DIR}/.github" FORCE)
    endif()
endif()
