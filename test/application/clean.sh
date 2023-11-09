#!/bin/bash

set -euo pipefail

rm -f .clang-format
rm -f .clang-tidy
rm -f .cmake-format.yaml
rm -f .gitignore
rm -f CMakePresets.json
rm -f toolchains

rm -rf build
rm -rf .github
