if(NOT COMMAND fmt_recipe)
    macro(fmt_recipe VERSION)
        add_versioned_package(
            NAME
            fmt
            GITHUB_REPOSITORY
            "fmtlib/fmt"
            GIT_TAG
            ${VERSION}
            OPTIONS
            "FMT_INSTALL OFF"
            "FMT_OS OFF")
    endmacro()
endif()

if(NOT COMMAND boost_hana_recipe)
    macro(boost_hana_recipe VERSION)
        add_versioned_package(
            NAME
            hana
            GITHUB_REPOSITORY
            "boostorg/hana"
            GIT_TAG
            ${VERSION}
            DOWNLOAD_ONLY
            YES)
        if(NOT TARGET boost_hana)
            add_library(boost_hana INTERFACE)
            target_include_directories(boost_hana
                                       INTERFACE "${hana_SOURCE_DIR}/include")
        endif()
    endmacro()
endif()

if(NOT COMMAND boost_sml_recipe)
    macro(boost_sml_recipe VERSION)
        add_versioned_package(
            NAME
            sml
            GITHUB_REPOSITORY
            "boost-ext/sml"
            GIT_TAG
            ${VERSION}
            OPTIONS
            "SML_BUILD_BENCHMARKS OFF"
            "SML_BUILD_EXAMPLES OFF"
            "SML_BUILD_TESTS OFF")
    endmacro()
endif()
