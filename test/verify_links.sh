#!/bin/bash

set -euo pipefail

echo "Verifying links in "`pwd`

links=( .clang-format .clang-tidy .cmake-format.yaml CMakePresets.json toolchains )
for l in "${links[@]}"
do
    if ! [[ -L "application/${l}" ]]; then
        echo "application/${l} is not symlinked"
        exit 1
    fi
done

if ! [[ -e "application/.github/workflows/unit_tests.yml" ]]; then
    echo "application/.github/workflows/unit_tests.yml was not created"
    exit 1
fi
if ! [[ -e "application/.gitignore" ]]; then
    echo "application/.gitignore was not created"
    exit 1
fi
