add_custom_target(benchmarks)
add_custom_target(build_benchmarks)

function(get_nanobench)
    if(NOT TARGET nanobench)
        add_versioned_package("gh:martinus/nanobench@4.3.11")
    endif()
endfunction()

function(add_benchmark name)
    set(options NANO)
    set(multiValueArgs FILES INCLUDE_DIRECTORIES LIBRARIES SYSTEM_LIBRARIES)
    cmake_parse_arguments(BM "${options}" "" "${multiValueArgs}" ${ARGN})

    add_executable(${name} EXCLUDE_FROM_ALL ${BM_FILES})
    target_compile_options(${name} PRIVATE -O3 -march=native)
    target_include_directories(${name} PRIVATE ${BM_INCLUDE_DIRECTORIES})
    target_link_libraries(${name} PRIVATE ${BM_LIBRARIES})
    target_link_libraries_system(${name} PRIVATE ${BM_SYSTEM_LIBRARIES})
    add_dependencies(build_benchmarks ${name})

    if(BM_NANO)
        get_nanobench()
        target_link_libraries_system(${name} PRIVATE nanobench)
    endif()

    add_custom_command(
        OUTPUT ${name}.results
        COMMAND $<TARGET_FILE:${name}> > "${name}.results"
        DEPENDS ${name})
    add_custom_target(run_${name} DEPENDS ${name}.results)
    add_dependencies(benchmarks "run_${name}")
endfunction()
