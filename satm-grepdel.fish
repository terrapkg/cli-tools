#!/usr/bin/fish
# Script to batch delete all packages matching a certain exact pattern from a set of repos
# in Subatomic repo manager
# usage: satm-grepdel.fish "pattern"
# set fish_trace 1

set SATM subatomic-cli

set FILTER $argv[1]

set DRY_RUN 1

# Array of repos

set REPOS terra38 terra39 terra40 terrarawhide

function subatomic_grep
    set -l REPO $argv[1]
    set -l PATTERN $argv[2]
    $SATM pkg list $REPO | grep $FILTER
end

function subatomic_delete
    set -l REPO $argv[1]
    set -l PACKAGE $argv[2]
    echo "Deleting spec $PACKAGE from $REPO"
    if test $DRY_RUN -eq 0
        $SATM pkg delete $REPO $PACKAGE
    else
        echo "(Dry run, not deleting)"
    end
end

function satm_iter_for_each_repo
    for REPO in $REPOS
        echo "Going through $REPO... with filter $FILTER"
        set -l PACKAGES (subatomic_grep $REPO $FILTER)
        for PACKAGE in $PACKAGES
            subatomic_delete $REPO $PACKAGE
        end
    end
end


echo "List of repos to delete from: $REPOS"
echo "Grep pattern: $FILTER"

satm_iter_for_each_repo
