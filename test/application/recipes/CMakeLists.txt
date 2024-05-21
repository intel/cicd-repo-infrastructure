add_custom_target(recipe_tests)

function(test_recipe NAME VERSION LIBNAME)
    cmake_language(CALL ${NAME}_recipe ${VERSION})
    add_executable(${NAME}_recipe_app ${NAME}_recipe.cpp)
    target_link_libraries(${NAME}_recipe_app PRIVATE ${LIBNAME})
    add_dependencies(recipe_tests ${NAME}_recipe_app)
endfunction()

test_recipe(fmt "10.2.1" fmt::fmt-header-only)
test_recipe(boost_sml "v1.1.11" sml)
test_recipe(boost_hana "boost-1.83.0" boost_hana)
