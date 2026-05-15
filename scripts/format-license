#!/usr/bin/env bash

# Attribution: jonah@fyralabs.com
# Input handling help from owen@fyralabs.com

# Input handling
if [ -n "$1" ]; then
    input="$1"
else
    EDITOR="${EDITOR:-vim}"
    tmpfile=$(mktemp)
    cat > "$tmpfile" <<'EOF'

Paste the license build output into the line above.
EOF
    $EDITOR "$tmpfile"
    input="$(cat "$tmpfile")"
    rm "$tmpfile"
fi

# Remove prefix from build output
cleaned_input=$(
    printf "%s\n" "$input" \
    | grep '│' \
    | sed 's/^.*│ # //'
)

# Canonicalization helpers
canonicalize_or_group() {
    sed 's/OR/\n/g' <<< "$1" \
    | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
    | grep -v '^$' \
    | sort \
    | paste -sd ' OR ' -
}

strip_outer_parens_if_any() {
    local s="$1"
    s="$(sed 's/^[[:space:]]*//;s/[[:space:]]*$//' <<< "$s")"
    if [[ "$s" == "("*")" ]]; then
        s="${s#(}"
        s="${s%)}"
    fi
    printf '%s\n' "$s"
}

canonicalize_full_expression() {
    local expr="$1"
    mapfile -t and_parts < <(sed 's/AND/\n/g' <<< "$expr")
    canonical_and_parts=()
    for part in "${and_parts[@]}"; do
        local trimmed no_parens canonical_or
        trimmed="$(sed 's/^[[:space:]]*//;s/[[:space:]]*$//' <<< "$part")"
        no_parens="$(strip_outer_parens_if_any "$trimmed")"
        canonical_or="$(canonicalize_or_group "$no_parens")"
        canonical_and_parts+=("$canonical_or")
    done
    printf "%s\n" "${canonical_and_parts[@]}" \
        | sort \
        | paste -sd ' AND ' -
}

# Duplicate detection: map canonical to original
declare -A canonical_to_original
declare -A canonical_seen

while IFS= read -r line; do
    raw="$line"
    canonical="$(canonicalize_full_expression "$raw")"
    if [[ -z "${canonical_to_original[$canonical]}" ]]; then
        canonical_to_original[$canonical]="$raw"
        canonical_seen[$canonical]=1
    fi
done <<< "$cleaned_input"

# Build list of unique original expressions
unique_originals=""
for canonical in "${!canonical_to_original[@]}"; do
    original="${canonical_to_original[$canonical]}"
    unique_originals+="$original"$'\n'
done

# Output unique original expressions, wrapped in (), joined by AND
printf "%s" "$unique_originals" \
| sed 's/\(.*OR.*\)/(\1)/' \
| awk 'NR==1{p=$0;next}{p=p" AND "$0}END{print p}'
