#!/bin/bash
: ${CONFIG:?Need to set CONFIG variable}
# Build entire subtree by grepping for a pattern and then building the subtree

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Builds every Anda project (package) in the current monorepo whose name matches a given pattern. Requires the CONFIG env var to be set."
    echo "Usage:    terra-subtree-build [--help | -h] $0 <pattern>"
    exit 0
fi

function usage {
    echo "Usage: $0 <pattern>"
    echo "Must be in an anda monorepo"
    exit 1
}

if [ -z "$1" ]; then
    usage
fi

PATTERN="$1"

function anda_build {
    local project=$1
    anda build -c $CONFIG $project
}

function get_packages {
    anda list | grep "$PATTERN" | awk '{print $2}' | tr -d '()'
}

for package in $(get_packages); do
    anda_build $package
done
