#!/usr/bin/env bash

echo -e "* $(date '+%a %b %d %Y') $(git config user.name) <$(git config user.email)> - VERSION \n- $1"
