#!/bin/bash -x

# Script that accepts input from stdin and deletes packages from a repo, useful for batch operations
# "Simplified" version of satm-grepdel.fish, but requires manual filtering. BYO filters.

# Usage:

# cat packages.txt | satm-rm-stdin.sh terra40
# where packages.txt is a list of packages to delete
# or:
# subatomic-cli pkg list terra40 | grep "pattern" | grep "pattern2" | satm-rm-stdin.sh terra40
# where the grep commands are used to filter the list of packages to delete


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