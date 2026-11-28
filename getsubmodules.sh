#!/usr/bin/env bash

# Attribution:
# cypress@fyralabs.com

set -euo pipefail

usage="Usage:    getsubmodules [--help | -h] [--start <source number>] [--no-licenses] <git repo url> [ref]"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Lists a git repository's submodules at a ref (default: HEAD) and prints the %global, Source and %submodule_setup lines for a spec, plus an update.rhai line to keep them updated."
    echo "$usage"
    echo "    --start <n>    number of the first submodule Source (default: 1)"
    echo "    --no-licenses  don't check out the submodules to print their licenses with tavro, which is slow for big ones"
    exit 0
fi

start=1
licenses=true
while [[ "${1:-}" == --* ]]; do
    case "$1" in
        --start)
            if [[ ! "${2:-}" =~ ^[0-9]+$ ]]; then
                echo "Error: --start needs a source number" >&2
                exit 1
            fi
            start="$2"
            shift 2
            ;;
        --no-licenses)
            licenses=false
            shift
            ;;
        *)
            echo "$usage" >&2
            exit 1
            ;;
    esac
done

if [[ -z "${1:-}" ]]; then
    echo "$usage" >&2
    exit 1
fi

url="${1%/}"
ref="${2:-HEAD}"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

git -C "$tmpdir" init -q
git -C "$tmpdir" remote add origin "$url"
if ! GIT_TERMINAL_PROMPT=0 git -C "$tmpdir" fetch -q --depth 1 --filter=blob:none --no-tags origin "$ref"; then
    echo "Error: could not fetch $ref from $url" >&2
    exit 1
fi

mapfile -t gitlinks < <(git -C "$tmpdir" ls-tree -r FETCH_HEAD | awk -F '\t' '$1 ~ /^160000 commit / {split($1, meta, " "); print meta[3] "\t" $2}')

if [[ ${#gitlinks[@]} -eq 0 ]]; then
    echo "$url has no submodules at $ref"
    exit 0
fi

git -C "$tmpdir" show FETCH_HEAD:.gitmodules > "$tmpdir/gitmodules"

submodule_url() {
    local path="$1" key
    while IFS= read -r -d '' key; do
        if [[ "${key#*$'\n'}" == "$path" ]]; then
            key="${key%%$'\n'*}"
            git config -f "$tmpdir/gitmodules" "${key%.path}.url"
            return
        fi
    done < <(git config -f "$tmpdir/gitmodules" -z --get-regexp '^submodule\..*\.path$')
}

resolve_url() {
    local base="${url%/}" rest="$1"
    if [[ "$rest" != ./* && "$rest" != ../* ]]; then
        echo "$rest"
        return
    fi
    while true; do
        if [[ "$rest" == ./* ]]; then
            rest="${rest#./}"
        elif [[ "$rest" == ../* ]]; then
            rest="${rest#../}"
            base="${base%/*}"
        else
            break
        fi
    done
    echo "$base/$rest"
}

archive_url() {
    local repo="${1%.git}" macro="$2" name
    name="${repo##*/}"
    case "$repo" in
        https://github.com/*) echo "$repo/archive/%{$macro}.tar.gz" ;;
        https://gitlab.*/* | https://*/gitlab/*) echo "$repo/-/archive/%{$macro}/$name-%{$macro}.tar.gz" ;;
        https://codeberg.org/* | https://gitea.com/*) echo "$repo/archive/%{$macro}.tar.gz" ;;
        *) return 1 ;;
    esac
}

globals=()
sources=()
setups=()
width=0
number="$start"

for gitlink in "${gitlinks[@]}"; do
    commit="${gitlink%%$'\t'*}"
    path="${gitlink#*$'\t'}"
    raw_url=$(submodule_url "$path")
    if [[ -z "$raw_url" ]]; then
        echo "Warning: $path is a gitlink without a .gitmodules entry, skipping it" >&2
        continue
    fi
    sub_url=$(resolve_url "$raw_url")
    macro="submodule_${path//[^[:alnum:]]/_}"
    if (( ${#macro} > width )); then
        width=${#macro}
    fi

    globals+=("$macro $commit")
    if ! archive=$(archive_url "$sub_url" "$macro"); then
        archive="<archive of $sub_url at %{$macro}>"
        echo "Warning: don't know the archive url format for $sub_url, fill in Source$number yourself" >&2
    fi
    sources+=("Source$number: $archive")
    setups+=("%submodule_setup $path")
    number=$(( number + 1 ))
done

for global in "${globals[@]}"; do
    printf '%%global %-*s %s\n' "$width" "${global%% *}" "${global#* }"
done
echo
label_width=$(( ${#number} + 8 ))
for source in "${sources[@]}"; do
    printf '%-*s %s\n' "$label_width" "${source%% *}" "${source#* }"
done
echo
echo "%prep"
printf '%s\n' "${setups[@]}"
echo

if $licenses && ! command -v tavro > /dev/null; then
    echo "Warning: tavro isn't installed, so the submodule licenses are left out" >&2
    licenses=false
fi

if $licenses; then
    git -C "$tmpdir" checkout -q FETCH_HEAD
    if ! GIT_TERMINAL_PROMPT=0 git -C "$tmpdir" submodule update -q --init --recursive --depth 1; then
        echo "Warning: some submodules couldn't be checked out, so their licenses are missing" >&2
    fi
    echo "# submodule licenses, from tavro"
    echo "# the submodules ship as Sources, so their licenses cover the source RPM too."
    echo "# if some submodules aren't built into the binary, make this SourceLicense: and list only the built ones in License:"
    tavro --submodules "$tmpdir" | sed 's/^/# /'
    echo "# License: <project license> AND $(tavro --submodules --preamble "$tmpdir" 2> /dev/null)"
    echo
fi

repo="${url%.git}"
case "$repo" in
    https://github.com/*) lookup="gh_submodules(\"${repo#https://github.com/}\", tag)" ;;
    https://gitlab.com/*) lookup="gitlab_submodules(\"${repo#https://gitlab.com/}\", tag)" ;;
    https://codeberg.org/*) lookup="codeberg_submodules(\"${repo#https://codeberg.org/}\", tag)" ;;
    *) lookup="git_submodules(\"$url\", tag)" ;;
esac
echo "// update.rhai"
echo "rpm.submodules($lookup);"
