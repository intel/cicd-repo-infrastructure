add_library(${INFRA_TARGET_NAMESPACE}sanitizers INTERFACE)

if(DEFINED ENV{SANITIZERS})
    set(SANITIZERS
        $ENV{SANITIZERS}
        CACHE STRING "Sanitizer options")
endif()

if(SANITIZERS)
    target_compile_options(
        ${INFRA_TARGET_NAMESPACE}sanitizers
        INTERFACE -g -fno-omit-frame-pointer -fno-optimize-sibling-calls
                  -fsanitize=${SANITIZERS} -fno-sanitize-recover=${SANITIZERS})

    string(REGEX MATCH "memory" SANITIZER_MEMORY "${SANITIZERS}")
    if(SANITIZER_MEMORY)
        target_compile_options(${INFRA_TARGET_NAMESPACE}sanitizers
                               INTERFACE -fsanitize-memory-track-origins)
    endif()

    target_link_options(${INFRA_TARGET_NAMESPACE}sanitizers INTERFACE
                        -fsanitize=${SANITIZERS})
endif()
