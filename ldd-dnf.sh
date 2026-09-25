#!/usr/bin/env bash

# Attribution:
# june@fyralabs.com
# -h flag: jonah@fyralabs.com

# -h flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Finds libraries that a package dynamically links to, automatically getting the name of each package that provides them."
    echo "Usage:    ldd-dnf [--help | -h] <path/to/binary.rpm>"
    exit 0
fi

ldd "$1" | awk '{ if ($3 != "") { print "\"*" $3 "\"" }}' | xargs dnf provides
