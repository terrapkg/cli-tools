#!/usr/bin/env bash

# Attribution:
# jonah@fyralabs.com

# -h flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Fetches the latest commit hash and date for a given git repository. Useful for nightly packages."
    echo "Usage:    getcommit [--help | -h] <git repo url>"
    exit 0
fi

if [[ -z "$1" ]]; then
    echo "Usage:    getcommit <git repo url>"
    exit 1
fi

url="$1"

# get default branch
default_branch=$(git ls-remote --symref "$url" HEAD 2>/dev/null \
    | awk '/^ref:/ {print $2}' \
    | sed 's#refs/heads/##')

if [[ -z "$default_branch" ]]; then
    echo "Error: Could not determine default branch for $url"
    exit 1
fi

# get latest commit hash
commit=$(git ls-remote "$url" "refs/heads/$default_branch" 2>/dev/null | awk '{print $1}')

if [[ -z "$commit" ]]; then
    echo "Error: Could not fetch commit hash"
    exit 1
fi

# fetch only latest commit obj
tmpdir=$(mktemp -d)
git -C "$tmpdir" init -q
git -C "$tmpdir" remote add origin "$url" >/dev/null 2>&1
git -C "$tmpdir" fetch --depth=1 origin "$default_branch" -q 2>/dev/null

# get commit date
commit_date=$(git -C "$tmpdir" show -s --format=%cs "$commit" 2>/dev/null | tr -d '-')

rm -rf "$tmpdir"

echo "%global commit $commit"
echo "%global commit_date $commit_date"
echo '%global shortcommit %(c=%{commit}; echo ${c:0:7})'
