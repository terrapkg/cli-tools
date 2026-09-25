#!/usr/bin/fish
# Script to batch delete all packages matching a certain exact pattern from a set of repos
# in Subatomic repo manager
# usage: satm-grepdel.fish "pattern"
# set fish_trace 1

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Batch delete all packages matching a certain exact pattern from a set of repos in Subatomic repo manager. Prints a list of packages to be deleted before confirming deletion, pass --no-dry-run to actually perform the deletion, or --dry-run to explicitly run in safe mode."
    echo "Usage:    satm-grepdel [--help | -h] [--dry-run | --no-dry-run] "<pattern>""
    exit 0
end


set SATM subatomic-cli

argparse 'dry-run' 'no-dry-run' -- $argv
    or exit 1

    if set -q _flag_dry_run
        echo "dry run mode on"
        set DRY_RUN 1

    else if set -q _flag_no_dry_run
        echo "dry run mode off"
        set DRY_RUN 0

    else
        echo "No mode specified, defaulting to safe dry-run"
        set DRY_RUN 1
    end

set FILTER $argv[1]

# Array of repos

set REPOS terra43 terra44 terra45 terrarawhide terrael10

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
