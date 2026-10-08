#!/usr/bin/bash

# Creates a directory with a curated .spec for a specified buildsystem, an anda.hcl, and an update.rhai within.
# Usage:    templates [-b <buildsystem>] <anda/path/to/pkgname/> [-h | --help]
#
# Options:
#  -b <buildsystem>   Build system template to use (default: generic)
#  -h, --help         Show this help

TEMPLATES_DEFAULT="/etc/xdg/terra-scripts/templates"
TEMPLATES="${XDG_CONFIG_HOME:-$HOME/.config}/terra-scripts/templates"

# initialize .config/templates/ if it doesnt exist yet
[[ -d $TEMPLATES ]] || { mkdir -p "$(dirname "$TEMPLATES")"; cp -r "$TEMPLATES_DEFAULT" "$TEMPLATES"; }

help() {
    cat <<EOF
Creates a directory with a curated .spec for a specified buildsystem, an anda.hcl, and an update.rhai within.
Usage:    templates [-b <buildsystem>] <anda/path/to/pkgname/>  [-h | --help]

Options:
 -b <buildsystem>   Build system template to use (defaults to generic if no flag is passed)
 -h, --help         Show this help

Supported Build Systems:
generic
autotools
autotools-declarative
cmake
cmake-declarative
meson
meson-declarative
OCaml
OCaml-declarative
# Planned: electron/webapp, tauri, ada, R, D, nim, assembly(lol), python (binary and library), rust (binary and library?), more.
# haskell: Tell you to use `cabal rpm`, or wrap `cabal rpm` and add a packager and changelog
EOF
}

for arg; do
    [[ $arg == -h || $arg == --help ]] && { usage; exit 0; }
done

buildsys=generic
[[ $1 == -b ]] && { buildsys=$2; shift 2; }
path=${1%/}

[[ $path == anda/* && ! -e $path ]] || { echo "Path must begin with anda/ and not already exist" >&2; exit 1; }

template="$TEMPLATES/${buildsys,,}.spec"
[[ -f $template ]] || { echo "Error: '$buildsys' does not have a template yet. see templates -h for a list of supported buildsystems" >&2; exit 1; }

pkgname=${path##*/}

mkdir -p "$path"
touch "$path/update.rhai"
cp "$template" "$path/$pkgname.spec"
cat > "$path/anda.hcl" <<EOF
project pkg {
  rpm {
    spec = "$pkgname.spec"
  }
}
EOF
