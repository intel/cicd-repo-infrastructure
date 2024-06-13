# CI/CD Repository Infrastructure

[![Unit Tests](https://github.com/intel/cicd-repo-infrastructure/actions/workflows/test.yml/badge.svg)](https://github.com/intel/cicd-repo-infrastructure/actions/workflows/test.yml)

This repository provides infrastructure to support CI in other repositories. It
is designed to be used with [CMake](https://cmake.org/) v3.25 or higher, and
consumed with [CPM](https://github.com/cpm-cmake/CPM.cmake).

See the [full documentation](https://intel.github.io/cicd-repo-infrastructure/).

## Quickstart

First, add `get_cpm.cmake` to your project's repository, [as documented
here](https://github.com/cpm-cmake/CPM.cmake#adding-cpm).

Then, the top of your CMakeLists.txt file should look something like this:

```cmake
cmake_minimum_required(VERSION 3.25)

project(my_project)

include(cmake/get_cpm.cmake)
cpmaddpackage("gh:intel/cicd-repo-infrastructure#abc123")
```

Where `abc123` is the version of this repository you want to depend on.

## Dependencies

This repository depends on:

- [Boost-ext.DI](https://github.com/boost-ext/di) at version 1.3.0
- [Catch2](https://github.com/catchorg/Catch2) at version 3.5.0
- [CPM.cmake](https://github.com/cpm-cmake/CPM.cmake) at version 0.38.2
- [GoogleTest](https://github.com/google/googletest) at version 1.14.0
- [GUnit](https://github.com/cpp-testing/GUnit) at version 1.14.0
- [RapidCheck](https://github.com/emil-e/rapidcheck) at git hash 1c91f40
- [Snitch](https://github.com/snitch-org/snitch) at version 1.2.4

