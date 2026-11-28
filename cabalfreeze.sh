#!/usr/bin/env bash

# Attribution:
# cypress@fyralabs.com

set -euo pipefail

usage="Usage:    cabalfreeze [--help | -h] [--index-state <timestamp | HEAD>] [path/to/package.spec]"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Generates the cabal.project.freeze for a Haskell spec that uses Terra's cabal macros and saves it next to the spec. It runs the spec's %prep with rpmbuild, so the freeze is the same one a build would make."
    echo "$usage"
    echo "    --index-state <ts>    Hackage index-state to resolve against, like 2026-11-20T00:00:00Z (default: HEAD, the latest)"
    echo "Without a spec, it uses the only .spec in the current directory."
    exit 0
fi

index_state=HEAD
if [[ "${1:-}" == "--index-state" ]]; then
    if [[ -z "${2:-}" ]]; then
        echo "Error: --index-state needs a timestamp or HEAD" >&2
        exit 1
    fi
    index_state="$2"
    shift 2
fi

spec="${1:-}"
if [[ -z "$spec" ]]; then
    shopt -s nullglob
    specs=(*.spec)
    shopt -u nullglob
    if [[ ${#specs[@]} -ne 1 ]]; then
        echo "Error: found ${#specs[@]} .spec files here, pass the one to use" >&2
        echo "$usage" >&2
        exit 1
    fi
    spec="${specs[0]}"
fi

if [[ ! -f "$spec" ]]; then
    echo "Error: $spec doesn't exist" >&2
    exit 1
fi

for cmd in rpmbuild spectool cabal jq; do
    if ! command -v "$cmd" > /dev/null; then
        echo "Error: $cmd isn't installed" >&2
        exit 1
    fi
done

if [[ "$(rpm -E '%{?cabal_prep_online:yes}')" != yes ]]; then
    echo "Error: the cabal macros aren't installed, install anda-srpm-macros" >&2
    exit 1
fi

spec_dir=$(cd "$(dirname "$spec")" && pwd)
spec_path="$spec_dir/$(basename "$spec")"

topdir=$(mktemp -d)
trap 'rm -rf "$topdir"' EXIT

mkdir -p "$topdir/SOURCES"
cp -a "$spec_dir/." "$topdir/SOURCES/"
if [[ ! -e "$topdir/SOURCES/cabal.project.freeze" ]]; then
    : > "$topdir/SOURCES/cabal.project.freeze"
fi

echo "Downloading sources..." >&2
if ! spectool -g -C "$topdir/SOURCES" "$spec_path" > "$topdir/spectool.log" 2>&1; then
    cat "$topdir/spectool.log" >&2
    echo "Error: couldn't download the sources" >&2
    exit 1
fi

echo "Running %prep against index-state $index_state..." >&2
if ! rpmbuild -bp --nodeps \
    --define "_topdir $topdir" \
    --define "_sourcedir $topdir/SOURCES" \
    --define "cabal_regenerate_freeze $index_state" \
    --define "__tavro_bin /bin/true" \
    "$spec_path" > "$topdir/prep.log" 2>&1; then
    tail -n 40 "$topdir/prep.log" >&2
    echo "Error: %prep failed, the end of its log is above" >&2
    exit 1
fi

freeze=$(find "$topdir/BUILD" -mindepth 2 -maxdepth 3 -name cabal.project.freeze -print -quit)
if [[ -z "$freeze" ]]; then
    echo "Error: %prep finished but didn't make a cabal.project.freeze. Does the spec use %cabal_prep_online?" >&2
    exit 1
fi

cp "$freeze" "$spec_dir/cabal.project.freeze"
echo "Wrote $spec_dir/cabal.project.freeze ($(grep -o '^index-state:.*' "$freeze"))"
