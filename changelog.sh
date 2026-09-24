#!/usr/bin/env bash

# Attribution:
# june@fyralabs.com
# Config functionality by jonah@fyralabs.com

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Generates metadata for a changelog entry."
    echo "Usage: changelog [--name=NAME] [--email=EMAIL] ["message"]"
    echo "Default name/email are based on your git config."
    exit 0
fi

conf_template="/etc/xdg/terra-scripts/changelog.conf"
conf="${XDG_CONFIG_HOME:-$HOME/.config}/terra-scripts/changelog.conf"

# Initialize config if it doesn't exist yet
[[ -f "$conf" ]] || { mkdir -p "$(dirname "$conf")"; cp "$conf_template" "$conf"; }

for arg in "$@"; do
    case "$arg" in
        --name=*) sed -i "s/^NAME=.*/NAME=${arg#--name=}/" "$conf" ;;
        --email=*) sed -i "s/^EMAIL=.*/EMAIL=${arg#--email=}/" "$conf" ;;
        *) msg="$arg" ;;
    esac
done

source "$conf"

name="${NAME:-$(git config user.name)}"
email="${EMAIL:-$(git config user.email)}"

echo -e "* $(date '+%a %b %d %Y') $name <$email> - VERSION-RELEASE \n- $msg"
