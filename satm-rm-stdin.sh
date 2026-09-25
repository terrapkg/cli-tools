#!/bin/bash -x

# Script that accepts input from stdin and deletes packages from a repo, useful for batch operations
# "Simplified" version of satm-grepdel.fish, but requires manual filtering. BYO filters.

# Usage:

# cat packages.txt | satm-rm-stdin.sh terra40
# where packages.txt is a list of packages to delete
# or:
# subatomic-cli pkg list terra40 | grep "pattern" | grep "pattern2" | satm-rm-stdin.sh terra40
# where the grep commands are used to filter the list of packages to delete

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Deletes packages piped in via stdin from a single Subatomic repo. An alternative to satm-grepdel.fish."
    echo "Usage:    cat packages-to-delete.txt | satm-rm-stdin <repo>"
    echo "          subatomic-cli pkg list <repo> | grep \"pattern-to-delete\" | satm-rm-stdin <repo>"
    echo "          satm-rm-stdin [--help | -h]"
    exit 0
fi

SATM=subatomic-cli

REPO=$1


usage() {
    echo "Usage: cat packages.txt | $0 <repo>"
    exit 1
}

if [ -z "$REPO" ]; then
    usage
fi

while read PACKAGE
do
    echo "Deleting spec $PACKAGE from $REPO"
    $SATM pkg delete $REPO $PACKAGE
done
