#!/bin/bash

set -euo pipefail

rm .clang-format
rm .clang-tidy
rm .cmake-format.yaml
rm .gitignore
rm CMakePresets.json
rm toolchains

rm -rf build
rm -rf .github
