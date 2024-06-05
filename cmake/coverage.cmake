add_library(coverage INTERFACE)
target_compile_options(
    coverage INTERFACE $<$<CXX_COMPILER_ID:Clang>:-fprofile-instr-generate>
                       $<$<CXX_COMPILER_ID:Clang>:-fcoverage-mapping>)
target_link_options(coverage INTERFACE
                    $<$<CXX_COMPILER_ID:Clang>:-fprofile-instr-generate>)

add_custom_target(cpp_coverage_report)

find_program(LLVM_PROFDATA_PROGRAM "llvm-profdata" HINTS ${CT_ROOT})
if(LLVM_PROFDATA_PROGRAM)
    message(STATUS "llvm-profdata found at ${LLVM_PROFDATA_PROGRAM}.")
    find_program(LLVM_COV_PROGRAM "llvm-cov" HINTS ${CT_ROOT})
    if(LLVM_COV_PROGRAM)
        message(STATUS "llvm-cov found at ${LLVM_COV_PROGRAM}.")

        add_custom_target(cpp_coverage)
        add_custom_command(
            OUTPUT ${PROJECT_BINARY_DIR}/combined.profdata
            COMMAND
                "${LLVM_PROFDATA_PROGRAM}" merge -sparse
                ${PROJECT_BINARY_DIR}/coverage/*.profdata -o
                ${PROJECT_BINARY_DIR}/combined.profdata
            DEPENDS cpp_coverage)

        add_custom_command(
            OUTPUT ${PROJECT_BINARY_DIR}/coverage_report.txt
            COMMAND
                "${LLVM_COV_PROGRAM}" report -show-instantiation-summary
                $<$<VERSION_GREATER_EQUAL:${CMAKE_CXX_COMPILER_VERSION},18>:-show-mcdc-summary>
                -instr-profile=${PROJECT_BINARY_DIR}/combined.profdata
                $<LIST:TRANSFORM,$<TARGET_GENEX_EVAL:cpp_coverage,$<TARGET_PROPERTY:cpp_coverage,COVERAGE_OBJECTS>>,PREPEND,--object=>
                > ${PROJECT_BINARY_DIR}/coverage_report.txt
            COMMAND_EXPAND_LISTS VERBATIM
            DEPENDS ${PROJECT_BINARY_DIR}/combined.profdata)
        add_custom_target(cpp_cov_report
                          DEPENDS ${PROJECT_BINARY_DIR}/coverage_report.txt)

        add_dependencies(cpp_coverage_report cpp_cov_report)
    else()
        message(
            STATUS
                "llvm-cov not found. Test coverage targets will be unavailable."
        )
    endif()
else()
    message(
        STATUS
            "llvm-profdata not found. Test coverage targets will be unavailable."
    )
endif()

function(add_coverage_target name)
    message(
        STATUS
            "add_coverage_target(${name}) is disabled because CMAKE_CXX_COMPILER_ID is ${CMAKE_CXX_COMPILER_ID}."
    )
endfunction()

if(NOT CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    return()
endif()

function(add_test_coverage_target name)
    if(LLVM_COV_PROGRAM)
        add_custom_command(
            OUTPUT coverage/${name}.profraw
            COMMAND env "LLVM_PROFILE_FILE=coverage/${name}.profraw"
                    $<TARGET_FILE:${name}>
            DEPENDS run_${name})
        add_custom_target(raw_coverage_${name} DEPENDS coverage/${name}.profraw)

        add_custom_command(
            OUTPUT ${PROJECT_BINARY_DIR}/coverage/${name}.profdata
            COMMAND
                "${LLVM_PROFDATA_PROGRAM}" merge -sparse
                coverage/${name}.profraw -o
                ${PROJECT_BINARY_DIR}/coverage/${name}.profdata
            DEPENDS raw_coverage_${name})
        add_custom_target(
            indexed_coverage_${name}
            DEPENDS ${PROJECT_BINARY_DIR}/coverage/${name}.profdata)

        add_custom_command(
            OUTPUT ${PROJECT_BINARY_DIR}/coverage/${name}.coverage_report.txt
            COMMAND
                "${LLVM_COV_PROGRAM}" report -show-instantiation-summary
                $<$<VERSION_GREATER_EQUAL:${CMAKE_CXX_COMPILER_VERSION},18>:-show-mcdc-summary>
                -instr-profile=${PROJECT_BINARY_DIR}/coverage/${name}.profdata
                -object $<TARGET_FILE:${name}> >
                ${PROJECT_BINARY_DIR}/coverage/${name}.coverage_report.txt
            COMMAND_EXPAND_LISTS VERBATIM
            DEPENDS indexed_coverage_${name})
        add_custom_target(
            coverage_report_${name}
            DEPENDS ${PROJECT_BINARY_DIR}/coverage/${name}.coverage_report.txt)

        add_dependencies(cpp_coverage "indexed_coverage_${name}")
        set_property(
            TARGET cpp_coverage
            APPEND
            PROPERTY COVERAGE_OBJECTS $<TARGET_FILE:${name}>)
    endif()
endfunction()
