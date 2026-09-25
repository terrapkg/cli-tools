#!/usr/bin/bash

# Usage example:
# sync-branches.sh username f44

# NOTE: Requires ripgrep

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Creates a branch sync pull request for when automatic bumps are out of sync across branches, or multiple backports are failing, by cloning terrapkg/packages over HTTPS, for a given release branch."
    echo "Usage:    sync-branches [--help | -h] <username> <branch> [-x]"
    exit 0
fi


if [[ "$3" == "-x" ]]; then
  set -x
fi

NAME="$1"
BRANCH="$2"
WORKDIR="$HOME/git/terra"
SYNC="sync-$BRANCH"
SYNCBRANCH="$NAME/chore/$SYNC"
SYNCDIR="$WORKDIR/frawhide-sync"
CLONE="git clone --recurse-submodules -j$(nproc) https://github.com/terrapkg/packages.git -b $BRANCH $SYNC"

function clean_files() {
for file in $(rg updbranch --files-with-matches --glob '!backup/'); do
DIRNAME=$(dirname $file)
BASENAME=$(basename $DIRNAME)
DIR=$(echo $DIRNAME | sed "s|/$BASENAME||g")
mkdir -p backup/$DIR
mv $DIRNAME backup/$DIR
done
for file in $(rg terra\\\\$releasever --files-with-matches --glob '!backup/'); do
DIRNAME=$(dirname $file)
mkdir -p backup/$DIRNAME
mv $file -t backup/$DIRNAME
done
for file in $(rg fedora\/\\\\$releasever --files-with-matches --glob '!backup/'); do
DIRNAME=$(dirname $file)
mkdir -p backup/$DIRNAME
mv $file -t backup/$DIRNAME
done
}

if [[ ! -d "$WORKDIR" ]]; then
  mkdir -p $WORKDIR
fi

if [[ "$PWD" != "$WORKDIR" ]]; then
  cd $WORKDIR
fi

if [[ ! -d "$SYNCDIR" ]]; then
  git clone --recurse-submodules -j$(nproc) https://github.com/terrapkg/packages.git -b frawhide "$SYNCDIR"
  pushd $SYNCDIR
  clean_files
  popd
else
  pushd $SYNCDIR
  git pull --no-edit
  popd
fi

$CLONE || { rm -rf $SYNC && $CLONE; }

pushd $SYNC
git checkout -b $SYNCBRANCH
clean_files
rm -rf anda/
cp -pr $SYNCDIR/anda -t $PWD
cp -pr backup/* -t $PWD
rm -rf backup
git add .
git commit -a -m "chore: Sync $BRANCH"
git push origin HEAD:$SYNCBRANCH || git push -f origin HEAD:$SYNCBRANCH
popd
