if(COMMAND boost_sml_recipe)
    return()
endif()

macro(boost_sml_recipe VERSION)
    add_versioned_package(
        NAME
        sml
        GIT_TAG
        ${VERSION}
        GITHUB_REPOSITORY
        boost-ext/sml
        OPTIONS
        "SML_BUILD_BENCHMARKS OFF"
        "SML_BUILD_EXAMPLES OFF"
        "SML_BUILD_TESTS OFF")
endmacro()

macro(mp_units_recipe VERSION)
    add_versioned_package("gh:gsl-lite/gsl-lite@0.40.0")
    set(gsl-lite_DIR "${gsl-lite_BINARY_DIR}")

    add_versioned_package(
        NAME
        fmt
        GITHUB_REPOSITORY
        "fmtlib/fmt"
        GIT_TAG
        9.1.0
        OPTIONS
        "FMT_INSTALL ON")
    set(fmt_DIR "${fmt_BINARY_DIR}")

    add_versioned_package(
        NAME
        mp-units
        GITHUB_REPOSITORY
        "mpusz/units"
        GIT_TAG
        ${VERSION}
        DOWNLOAD_ONLY
        YES)
    add_subdirectory("${mp-units_SOURCE_DIR}/src")
endmacro()
