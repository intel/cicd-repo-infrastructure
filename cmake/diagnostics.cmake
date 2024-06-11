add_library(diagnostics INTERFACE)

target_compile_options(
    diagnostics
    INTERFACE
        $<$<CXX_COMPILER_ID:Clang>:-ferror-limit=8>
        $<$<CXX_COMPILER_ID:GNU>:-fmax-errors=8>
        $<$<OR:$<CXX_COMPILER_ID:Clang>,$<CXX_COMPILER_ID:GNU>>:-ftemplate-backtrace-limit=0>
        $<$<AND:$<STREQUAL:${CMAKE_GENERATOR},Ninja>,$<OR:$<CXX_COMPILER_ID:Clang>,$<CXX_COMPILER_ID:GNU>>>:-fdiagnostics-color>
)
