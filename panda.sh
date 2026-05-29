#!/usr/bin/env bash
set -euo pipefail

BRANCH="frawhide"

usage() {
  cat <<EOF
  --podman-anda (panda)--
Usage: panda [-b <branch>] <anda arguments>

helper script for running anda in the pet container more easily.

just run panda and pass arguments like you would to normal anda.

Options:
  -b, --branch <branch>   Builder image branch to use (default: frawhide)
                          Examples: frawhide, f44, f43
  -h                      Show this help message

Examples:
  panda build -c terra-rawhide-x86_64 anda/system/vicinae/pkg (runs in the Rawhide container with the Rawhide mock config)
  panda -b f43 build -c terra-f44-x86_64 anda/system/vicinae/pkg (runs in the f43 container with the f44 mock config)

Notes:
  you can mix and match mock configs and container versions, but we suggest using the Rawhide container unless you run into trouble.
  --help passes through to anda directly, use -h to see this
  god bless the container cirucs
  
built with love in minneapolis (by catgirls! :3)
₍^. .^₎⟆ 
EOF
}

if [[ $# -eq 0 ]]; then
  echo "no arguments, here's the help" >&2
  echo >&2
  usage >&2
  exit 1
fi

case "${1:-}" in
  -h)
    usage
    exit 0
    ;;
  -b|--branch)
    if [[ -z "${2:-}" ]]; then
      echo "provide a branch, if you just want rawhide don't use --branch" >&2
      exit 1
    fi
    BRANCH="$2"
    shift 2
    if [[ $# -eq 0 ]]; then
      echo "no anda arguments provided, this won't do anything, read anda docs" >&2
      exit 1
    fi
    ;;
  -*)
    # flags get passed through to anda regardless, it will handle errors itself
    ;;
esac

exec podman run --rm \
  --cap-add=SYS_ADMIN \
  --privileged \
  --volume ./:/anda \
  --volume mock_cache:/var/cache/mock \
  --workdir /anda \
  ghcr.io/terrapkg/builder:"$BRANCH" \
  anda "$@"
