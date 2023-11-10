add_library(profile-compilation INTERFACE)

target_compile_options(
    profile-compilation
    INTERFACE -ftime-report $<$<CXX_COMPILER_ID:Clang>:-ftime-trace>
              $<$<CXX_COMPILER_ID:Clang>:-ftime-trace-granularity=10>)
