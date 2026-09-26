#!/usr/bin/bash

# Automatically merges backports (if found) for a given PR URL.
# Usage:    backports [--help | -h] [-y] <pr-url>
# NOTE:     Requires gh (authenticated) and jq

yes=0
pr_url=""
for arg in "$@"; do
    case "$arg" in
        -h|--help)
            echo "Automatically merges backports for a given PR URL."
            echo "Usage:    backports [--help | -h] [-y] <pr-url>"
            echo "NOTE:     Requires gh (authenticated) and jq"
            exit 0
            ;;
        -y) yes=1 ;;
        *) pr_url="$arg" ;;
    esac
done

if [[ -z "$pr_url" ]]; then
    printf "Usage:\tbackports [-y] <pr_url>\n"
    exit 1
fi

user="raboneko"

if [[ ! "$pr_url" =~ github\.com/([^/]+)/([^/]+)/pull/([0-9]+) ]]; then
    echo "Error: invalid PR URL: $pr_url"
    exit 1
fi

owner="${BASH_REMATCH[1]}"
repo="${BASH_REMATCH[2]}"
pr="${BASH_REMATCH[3]}"

comments=$(gh api "repos/$owner/$repo/issues/$pr/comments" --paginate)

bodies=$(echo "$comments" | jq -r --arg user "$user" '
    [.[] | select(.user.login | ascii_downcase == ($user | ascii_downcase)) | .body] | join("\n")
')

links=$(echo "$bodies" \
    | grep -oE "https://github\.com/[^/[:space:])]+/[^/[:space:])]+/pull/[0-9]+" \
    | sort -u \
    | grep -v "/pull/$pr\$")

if [[ -z "$links" ]]; then
    echo "Backports haven't been created yet for $owner/$repo#$pr."
    exit 1
fi

declare -A branch_of
while IFS= read -r line; do
    [[ "$line" =~ \|[^\|]*\|[[:space:]]*([A-Za-z0-9_.]+)[[:space:]]*\|.*\((https://github\.com/[^/]+/[^/]+/pull/[0-9]+)\) ]] || continue
    branch_of["${BASH_REMATCH[2]}"]="${BASH_REMATCH[1]}"
done <<< "$bodies"

if [[ "$yes" != 1 ]]; then
    pr_info=$(gh api "repos/$owner/$repo/pulls/$pr")
    title=$(echo "$pr_info" | jq -r .title)
    author=$(echo "$pr_info" | jq -r .user.login)
    created=$(date -d "$(echo "$pr_info" | jq -r .created_at)" +"%b %d, %Y")

    echo "$title"
    echo "$author - $created"
    echo ""

    read -rp "Are you sure you want to merge backports for this PR? [Y/n] " ans
    [[ "${ans:-Y}" =~ ^[Yy] ]] || { echo "Aborted."; exit 0; }
    echo
fi

while read -r link; do
    [[ "$link" =~ github\.com/([^/]+)/([^/]+)/pull/([0-9]+) ]] || continue
    o="${BASH_REMATCH[1]}"; r="${BASH_REMATCH[2]}"; n="${BASH_REMATCH[3]}"
    tag=""; [[ -n "${branch_of[$link]:-}" ]] && tag="[${branch_of[$link]}] "

    gh pr review "$n" --repo "$o/$r" --approve >/dev/null 2>&1 && a="approved" || a="approve failed"
    gh pr merge "$n" --repo "$o/$r" --squash --auto >/dev/null 2>&1 && m="squash-merge enabled" || m="merge failed"

    echo "${tag}${link} -> $a, $m"
done <<< "$links"
