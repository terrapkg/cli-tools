#!/usr/bin/env bash

# Attribution:
# june@fyralabs.com

# -h flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Generates metadata for a changelog entry."
    echo "Usage: changelog"
    exit 0
fi

echo -e "* $(date '+%a %b %d %Y') $(git config user.name) <$(git config user.email)> - VERSION-RELEASE \n- $1"
