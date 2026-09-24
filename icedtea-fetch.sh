#!/usr/bin/bash

# Inspired by the Red Hat script to fetch IcedTea.
# Uses IcedTea Git sources and rewritten from scratch.
# Written for the Terra Java Preservation/Adoption Project.
#
# Copyright (C) 2026 Fyra Labs, LLC.
# Written by Gilver Eckhart <roachy@fyralabs.com>
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Packager usage:
# Call this script using a pre.rhai file or a pre_script argument in the anda.hcl.
# Pass --version=* or --branch=* depending on the source **or** use sed or another method of in-place file editing to subsititute __ICEDTEA_VERSION or __ICEDTEA_BRANCH at runtime.
# You MAY pass --tarball or --git to the script. However, you do not need to as it will default to Git. NOTE: The final tarball name may change based on the source.
# If using --tarball you NEED --version=*. If passing --git or no source method flags you NEED --branch=*.
# Arguments you should **not** need but exist if you do: --url (set the URL to download source tarballs from), --repo (URL to the Git repo), --key (the GPG key to check against).
# While this all sounds complicated, an average run of this script will simply look like /path/to/icedtea-fetch.sh --branch 6.0. The rest is for edge cases.
#
# Other flags:
# -j*/--jobs */--jobs=*: The number of jobs that git clone will use. Defaults to the value of nproc.
# -q/--quiet: Remove verbosity.
# -v*: Level of verbosity. Ranges from -v to -vvv. Default is -vv.

ERR='\033[0;31m'
OR='\033[0m'
WARN='\033[1;33m'
ING="${OR}"
NO='\033[0;34m'
TE="${OR}"
SUCC='\033[0;32m'
ESS="${OR}"

function print_help() {
echo -e "Usage: icedtea-fetch.sh [options] [arguments]\n

Options:
  --git                           Use Git source fetching. Default behavior. Requires passing --branch.
  --tarball                       Use Tarball source fetching. Requires passing --version.

  --version ..., --version=...    The version of IcedTea to fetch when downloading a tarball source.
  --branch ..., --branch=...      The branch to clone when using a Git source.

  -q, --quiet                     No verbosity. No verbose flags are passed. NOTE: Does not set quiet flags on individual commands.
  -v                              Low level verbosity. Only passes verbose flags to commands.
  -vv                             Medium level verbosity. Passes verbose flags to commands and prints commands when running them.
  -vvv                            Maximum verbosity. The entire script is run through set -x. For more information see the set builtin documentation.
                                  https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html

  -j..., --jobs ..., --jobs=...   The number of jobs to run in parallel for Git commands. Defaults to the output of nproc.

  --repo ..., --repo=...          The repository to Git clone from when using a Git source. Defaults to the official IcedTea repo.
  --url ..., --url=...            The URL to download the source tarball and associated signature and GPG key from when using --tarball.
  --key ..., --key=...            The GPG key to check the source tarball against when using --tarball. Defaults to the last known GPG key for IcedTea.

  -h, --help                      Print help output and exit."
exit 0
}

# Parse script arguments to change default behavior at runtime.
OPTS=("$@")

# Parse help arguments ahead of time
case ${OPTS[@]} in
  "--help" | *" --help"* | *"--help "* | "-h" | *" -h"* | *"-h "*)
    print_help
  ;;
esac


for i in "${!OPTS[@]}"; do
  # Used to process the value of positional arguments
  v="$(( i + 1 ))"
  # Used to parse positional options
  x="$(( i - 1 ))"
  opt="${OPTS[$i]}"
  arg="${OPTS[$v]}"
  argopt="${OPTS[$x]}"
  if [[ "${opt}" == "--git" ]]; then
    if [[ -n "${USE_GIT}" ]]; then
      echo -e "${ERR}error:${OR} Too many arguments for source fetching passed.\n"
      exit 3
    else
      USE_GIT="true"
    fi
  elif [[ "${opt}" == "--tarball" ]]; then
    if [[ -n "${USE_GIT}" ]]; then
      echo -e "${ERR}error:${OR} Too many arguments for source fetching passed.\n"
      exit 3
    else
      USE_GIT="false"
    fi
  elif [[ "${opt}" == "--branch" ]]; then
    if [[ "${USE_GIT}" == "false" ]]; then
      echo -e "${WARN}warning:${ING} Using tarball source fetching, ignoring extra flag --branch.\n"
    else
      BRANCH="${arg}"
    fi
  elif [[ "${opt}" == --branch=* ]]; then
    if [[ "${USE_GIT}" == "false" ]]; then
      echo -e "${WARN}warning:${ING} Using tarball source fetching, ignoring extra flag --branch.\n"
    else
      BRANCH="${opt//--branch=/}"
    fi
  elif [[ "${opt}" == "--version" ]]; then
    if [[ -z "${USE_GIT}" || "${USE_GIT}" == "true" ]]; then
      echo -e "${WARN}warning:${ING} Using Git source fetching, ignoring extra argument --version.\n"
    else
      VERSION="${arg}"
    fi
  elif [[ "${opt}" == --version=* ]]; then
    if [[ -z "${USE_GIT}" || "${USE_GIT}" == "true" ]]; then
      echo -e "${WARN}warning:${ING} Using Git source fetching, ignoring extra argument --version.\n"
    else
      VERSION="${opt//--version=/}"
    fi
  elif [[ "${opt}" == "--key" ]]; then
    GPG_KEY="${arg}"
  elif [[ "${opt}" == --key=* ]]; then
    GPG_KEY="${opt//--key=/}"
  elif [[ "${opt}" == "--repo" ]]; then
    if [[ "${USE_GIT}" == "false" ]]; then
      echo -e "${WARN}warning:${ING} Using tarball source fetching, ignoring extra argument --repo.\n"
    else
      REPO="${arg}"
    fi
  elif [[ "${opt}" == --repo=* ]]; then
    if [[ "${USE_GIT}" == "false" ]]; then
      echo -e "${WARN}warning:${ING} Using tarball source fetching, ignoring extra argument --repo.\n"
    else
      REPO="${opt//--repo=/}"
    fi
  elif [[ "${opt}" == "--url" ]]; then
    if [[ -z "${USE_GIT}" || "${USE_GIT}" == "true" ]]; then
      echo -e "${WARN}warning:${ING} Using Git source fetching, ignoring extra argument --url.\n"
    else
      URL="${arg}"
    fi
  elif [[ "${opt}" == --url=* ]]; then
    if [[ -z "${USE_GIT}" || "${USE_GIT}" == "true" ]]; then
      echo -e "${WARN}warning:${ING} Using Git source fetching, ignoring extra argument --url.\n"
    else
      URL="${opt//--url=/}"
    fi
  elif [[ "${opt}" == "-j" ]]; then
    JOBS="${arg}"
  elif [[ "${opt}" =~ -j[0-9] ]]; then
    JOBS="${opt//-j/}"
  elif [[ "${opt}" == "--jobs" ]]; then
    JOBS="${arg}"
  elif [[ "${opt}" == --jobs=* ]]; then
    JOBS="${opt//--jobs=/}"
  elif [[ "${opt}" =~ ^-v{0,3}$ ]]; then
    if [[ -n "${VERBOSITY_LEVEL}" ]]; then
      echo -e "${ERR}error:${OR} Too many options for logging passed.\n"
      exit 3
    else
      VERBOSITY_LEVEL="${opt//-/}"
    fi
  elif [[ "${opt}" == "-q" || "${opt}" == "--quiet" ]]; then
    if [[ -n "${VERBOSITY_LEVEL}" ]]; then
      echo -e "${ERR}error:${OR} Too many options for logging passed.\n"
      exit 3
    else
      VERBOSITY_LEVEL="none"
    fi
  elif [[ "${argopt}" != "--branch" && "${argopt}" != "--version" && "${argopt}" != "--jobs" && "${argopt}" != "--key" && "${argopt}" != "--repo" && "${argopt}" != "--url" ]]; then
    echo -e "${ERR}error:${OR} Unrecognized option ${opt}."
    exit 3
  fi
done

# This is set later because the argument parsing requires checking if variables are empty.
set -euo pipefail

NCPUS="${JOBS:-$(nproc)}"
VERBOSITY="${VERBOSITY_LEVEL:-vv}"

if [[ "${VERBOSITY}" == "vvv" ]]; then
  set -x
fi

ICEDTEA_USE_GIT="${USE_GIT:-true}"

ICEDTEA_VERSION="${VERSION:-__ICEDTEA_VERSION}"
ICEDTEA_BRANCH_VERSION="${BRANCH:-__ICEDTEA_BRANCH}"
ICEDTEA_DOWNLOAD_URL="${URL:-https://icedtea.classpath.org/download/source}"
ICEDTEA_GIT_URL="${REPO:-https://github.com/icedtea-git/icedtea}"
ICEDTEA_SIGNING_KEY="${GPG_KEY:-CFDA0F9B35964222}"

SOURCE_DIR="${PWD}"

WORKDIR="$(mktemp -d)"

pushd "${WORKDIR}"

if [[ ! -f "${SOURCE_DIR}/jconsole.desktop.in" ]]; then
    echo -e "\nWrong source directory or needed files are missing. Rhai mistake?"
    exit 3
fi

echo -e "\n*** Checking basic script dependencies."

echo "Looking for required script dependency which..."
WHICH="$(which which || :)"
if [[ "${WHICH}" == "" ]]; then
  echo "-- ERROR: which not found."
  echo -e "\n${ERR}error:${OR} Some script dependencies were not satisfied."
  exit 3
else
  echo "-- Found which at ${WHICH}."
fi

echo "Looking for required script dependency Tar..."
TAR="$(which tar || :)"
if [[ "${TAR}" == "" ]]; then
  echo "-- ERROR: Tar not found."
  echo -e "\n${ERR}error:${OR} Some script dependencies were not satisfied."
  exit 3
else
  echo "-- Found Tar at ${TAR}."
fi

echo -e "\nBasic dependencies satisfied.\n"

if [[ "${ICEDTEA_USE_GIT}" == "true" ]]; then

    echo -e "${NO}Mode:${TE} Git clone.\n"

    echo -e "*** Checking script dependencies for source fetch method."

    echo "Looking for required script dependency Git..."
    GIT="$(which git)"
    if [[ "${GIT}" == "" ]]; then
      echo "-- ERROR: Git not found."
      echo -e "\n error: Some script dependencies were not satisfied."
      exit 3
    else
      echo "-- Found Git at ${GIT}."
    fi

    echo "Looking for required script dependency grep..."
    GREP="$(which grep || :)"
    if [[ "${GREP}" == "" ]]; then
      echo "-- ERROR: grep not found."
      echo -e "\n${ERR}error:${OR} Some script dependencies were not satisfied."
      exit 3
    else
      echo "-- Found grep at ${GREP}."
    fi

    echo -e "\nDependencies satisfied.\n"

    echo "Git cloning source."
    # advice.detachedHead is disabled because it takes up a lot of terminal space and we want readable logs.
    if [[ "${VERBOSITY}" == "vv" ]]; then
      ( set -x; git clone -c advice.detachedHead=false "-j${NCPUS}" "${ICEDTEA_GIT_URL}.git" -b "${ICEDTEA_BRANCH_VERSION}" )
    else
      git clone -c advice.detachedHead=false "-j${NCPUS}" "${ICEDTEA_GIT_URL}.git" -b "${ICEDTEA_BRANCH_VERSION}"
    fi


    echo -e "\nGetting version information."
    BASE_VER="$(grep '^AC_INIT' icedtea/configure.ac|cut -d ',' -f 2|tr -d '[:space:][]')"
    echo "-- Base version from configure: ${BASE_VER}"

    GIT_REV="$(git -C icedtea rev-parse --short HEAD)"
    echo -e "-- Git revision: ${GIT_REV}\n"

    ICEDTEA_VERSION="${BASE_VER}-${GIT_REV}"

    echo -e "\nCopying required files to icedtea-${ICEDTEA_VERSION}."
    if [[ "${VERBOSITY}" != "none" ]]; then
      if [[ "${VERBOSITY}" == "vv" ]]; then
        ( set -x; mkdir -v "icedtea-${ICEDTEA_VERSION}" )
      else
        mkdir -v "icedtea-${ICEDTEA_VERSION}"
      fi
    else
      mkdir "icedtea-${ICEDTEA_VERSION}"
    fi
    if [[ "${VERBOSITY}" == "vv" ]]; then
      ( set -x
      cp -a "${SOURCE_DIR}/jconsole.desktop.in" -t "icedtea-${ICEDTEA_VERSION}"
      cp -a icedtea/tapset -t "icedtea-${ICEDTEA_VERSION}"
      )
    else
      cp -a "${SOURCE_DIR}/jconsole.desktop.in" -t "icedtea-${ICEDTEA_VERSION}"
      cp -a icedtea/tapset -t "icedtea-${ICEDTEA_VERSION}"
    fi

    echo -e "\nCleaning up Git source."
    if [[ "${VERBOSITY}" == "vv" ]]; then
      ( set -x; rm -rf icedtea )
    else
      rm -rf icedtea
    fi

else

    echo -e "${NO}Mode:${TE} Tarball download.\n"

    echo "*** Checking script dependencies for source fetch method."

    echo "Looking for required script dependency Wget..."
    WGET="$(which wget || :)"
    if [[ "${WGET}" == "" ]]; then
      echo "-- ERROR: Wget not found."
      echo -e "\n${ERR}error:${OR} Some script dependencies were not satisfied."
      exit 3
    else
      echo "-- Found Wget at ${WGET}."
    fi

    echo "Looking for required script dependency GPG..."
    GPG="$(which gpg || :)"
    if [[ "${GPG}" == "" ]]; then
      echo "-- ERROR: GPG not found."
      echo -e "\n${ERR}error:${OR} Some script dependencies were not satisfied."
      exit 3
    else
      echo "-- Found GPG at ${GPG}."
    fi

    echo "Looking for required script dependency sha256sum..."
    SHASUM="$(which sha256sum || :)"
    if [[ "${SHASUM}" == "" ]]; then
      echo "-- ERROR: sha256sum not found."
      echo -e "\n${ERR}error:${OR} Some script dependencies were not satisfied."
      exit 3
    else
      echo "-- Found sha256sum at ${SHASUM}."
    fi

    echo -e "\nDependencies satisfied.\n"

    echo "Downloading source tarball."
    if [[ "${VERBOSITY}" != "none" ]]; then
      if [[ "${VERBOSITY}" == "vv" ]]; then
        ( set -x; wget -v "${ICEDTEA_DOWNLOAD_URL}/icedtea-${ICEDTEA_VERSION}.tar.xz" )
      else
        wget -v "${ICEDTEA_DOWNLOAD_URL}/icedtea-${ICEDTEA_VERSION}.tar.xz"
      fi
    else
      wget "${ICEDTEA_DOWNLOAD_URL}/icedtea-${ICEDTEA_VERSION}.tar.xz"
    fi

    echo -e "\nDownloading tarball shasum."
    if [[ "${VERBOSITY}" != "none" ]]; then
      if [[ "${VERBOSITY}" == "vv" ]]; then
        ( set -x; wget -v "${ICEDTEA_DOWNLOAD_URL}/icedtea-${ICEDTEA_VERSION}.sha256" )
      else
        wget -v "${ICEDTEA_DOWNLOAD_URL}/icedtea-${ICEDTEA_VERSION}.sha256"
      fi
    else
      wget "${ICEDTEA_DOWNLOAD_URL}/icedtea-${ICEDTEA_VERSION}.sha256"
    fi

    echo -e "\nDownloading tarball signature."
    if [[ "${VERBOSITY}" != "none" ]]; then
      if [[ "${VERBOSITY}" == "vv" ]]; then
        ( set -x; wget -v "${ICEDTEA_DOWNLOAD_URL}/icedtea-${ICEDTEA_VERSION}.tar.xz.sig" )
      else
        wget -v "${ICEDTEA_DOWNLOAD_URL}/icedtea-${ICEDTEA_VERSION}.tar.xz.sig"
      fi
    else
      wget "${ICEDTEA_DOWNLOAD_URL}/icedtea-${ICEDTEA_VERSION}.tar.xz.sig"
    fi

    echo -e "\nVerifying checksum."
    if [[ "${VERBOSITY}" == "vv" ]]; then
      ( set -x; sha256sum --check --ignore-missing "icedtea-${ICEDTEA_VERSION}.sha256" )
    else
      sha256sum --check --ignore-missing "icedtea-${ICEDTEA_VERSION}.sha256"
    fi

    echo -e "\nImporting signing key."
    if [[ "${VERBOSITY}" != "none" ]]; then
      if [[ "${VERBOSITY}" == "vv" ]]; then
        ( set -x; gpg -v --keyserver hkps://keyserver.ubuntu.com --recv-keys "${ICEDTEA_SIGNING_KEY}" )
      else
        gpg -v --keyserver hkps://keyserver.ubuntu.com --recv-keys "${ICEDTEA_SIGNING_KEY}"
      fi
    else
      gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys "${ICEDTEA_SIGNING_KEY}"
    fi

    echo -e "\nVerifying signature."
    if [[ "${VERBOSITY}" != "none" ]]; then
      if [[ "${VERBOSITY}" == "vv" ]]; then
        ( set -x; gpg -v --verify "icedtea-${ICEDTEA_VERSION}.tar.xz.sig" "icedtea-${ICEDTEA_VERSION}.tar.xz" || { { set +x; } 2>/dev/null; echo "Signature verification failed." && exit 3; } )
      else
        gpg -v --verify "icedtea-${ICEDTEA_VERSION}.tar.xz.sig" "icedtea-${ICEDTEA_VERSION}.tar.xz" || { echo "Signature verification failed." && exit 3; }
      fi
    else
      gpg --verify "icedtea-${ICEDTEA_VERSION}.tar.xz.sig" "icedtea-${ICEDTEA_VERSION}.tar.xz" || { echo "Signature verification failed." && exit 3; }
    fi

    echo -e "\nUnpacking tarball."
    if [[ "${VERBOSITY}" != "none" ]]; then
      if [[ "${VERBOSITY}" == "vv" ]]; then
        ( set -x; tar xvJf "icedtea-${ICEDTEA_VERSION}.tar.xz" "icedtea-${ICEDTEA_VERSION}/tapset" "icedtea-${ICEDTEA_VERSION}/jconsole.desktop.in" )
      else
        tar xvJf "icedtea-${ICEDTEA_VERSION}.tar.xz" "icedtea-${ICEDTEA_VERSION}/tapset" "icedtea-${ICEDTEA_VERSION}/jconsole.desktop.in"
      fi
    else
      tar xJf "icedtea-${ICEDTEA_VERSION}.tar.xz" "icedtea-${ICEDTEA_VERSION}/tapset" "icedtea-${ICEDTEA_VERSION}/jconsole.desktop.in"
    fi

    echo -e "\nCleaning up."
    if [[ "${VERBOSITY}" != "none" ]]; then
      if [[ "${VERBOSITY}" == "vv" ]]; then
        ( set -x
        rm -vf "icedtea-${ICEDTEA_VERSION}.tar.xz"
        rm -vf "icedtea-${ICEDTEA_VERSION}.tar.xz.sig"
        rm -vf "icedtea-${ICEDTEA_VERSION}.sha256"
        )
      else
        rm -vf "icedtea-${ICEDTEA_VERSION}.tar.xz"
        rm -vf "icedtea-${ICEDTEA_VERSION}.tar.xz.sig"
        rm -vf "icedtea-${ICEDTEA_VERSION}.sha256"
      fi
    else
      rm -f "icedtea-${ICEDTEA_VERSION}.tar.xz"
      rm -f "icedtea-${ICEDTEA_VERSION}.tar.xz.sig"
      rm -f "icedtea-${ICEDTEA_VERSION}.sha256"
    fi
fi

echo -e "\nReplacing files."
if [[ "${VERBOSITY}" != "none" ]]; then
  if [[ "${VERBOSITY}" == "vv" ]]; then
    ( set -x; mv -v "icedtea-${ICEDTEA_VERSION}/jconsole.desktop.in" -t "${SOURCE_DIR}" )
  else
    mv -v "icedtea-${ICEDTEA_VERSION}/jconsole.desktop.in" -t "${SOURCE_DIR}"
  fi
else
  mv "icedtea-${ICEDTEA_VERSION}/jconsole.desktop.in" -t "${SOURCE_DIR}"
fi

echo -e "\nCreating tapsets tarball."
if [[ "${VERBOSITY}" != "none" ]]; then
  if [[ "${VERBOSITY}" == "vv" ]]; then
     (
     set -x
     mv -v "icedtea-${ICEDTEA_VERSION}" openjdk
     tar cvJf "${SOURCE_DIR}/tapsets-icedtea-${ICEDTEA_VERSION}.tar.xz" openjdk
     )
  else
    mv -v "icedtea-${ICEDTEA_VERSION}" openjdk
    tar cvJf "${SOURCE_DIR}/tapsets-icedtea-${ICEDTEA_VERSION}.tar.xz" openjdk
  fi
else
  mv "icedtea-${ICEDTEA_VERSION}" openjdk
  tar cJf "${SOURCE_DIR}/tapsets-icedtea-${ICEDTEA_VERSION}.tar.xz" openjdk
fi

echo -e "\nCleaning up."
if [[ "${VERBOSITY}" != "none" ]]; then
  if [[ "${VERBOSITY}" == "vv" ]]; then
    ( set -x; rm -rvf openjdk )
  else
    rm -rvf openjdk
  fi
else
  rm -rf openjdk
fi

echo ""

popd

echo -e "\nCleaning up working directory."
if [[ "${VERBOSITY}" == "vv" ]]; then
  ( set -x; rm -rf "${WORKDIR}" )
else
  rm -rf "${WORKDIR}"
fi

echo -e '\nSource setup complete!'
echo -e "Your tapsets tarball is ${SUCC}tapsets-icedtea-${ICEDTEA_VERSION}.tar.xz${ESS}."

exit 0
