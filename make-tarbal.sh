#!/bin/bash -

set -e
set -C

trap 'cleanup' QUIT EXIT

OLD_IFS=$IFS
IFS='
 	'

function cleanup () {
    rm -rf $TMPDIR
    IFS="$OLD_IFS"
}

#get all modules
git submodule init > /dev/null
git submodule update > /dev/null

readonly PROGRAM=$(basename "$0")
readonly VERSION=$(grep VERSION nginx/src/core/nginx.h | head -n 1 | sed -e 's:.*"\(.*\)".*:\1:')

OLD_PWD=$(pwd)
TMPDIR=$(mktemp -d)
TMPFILE="$TMPDIR/$PROGRAM"
TOARCHIVE="$TMPDIR/$PROGRAM.toarchive"
SEPARATE=0
OUT_FILE=${OLD_PWD}/nginx-catap-${VERSION}.tar

PREFIX="nginx-catap-${VERSION}"
TREEISH=HEAD

if [ $(git config -l | grep -q '^core\.bare=false'; echo $?) -ne 0 ]; then
    echo "$PROGRAM must be run from a git working copy (i.e., not a bare repository)."
    exit
fi

git archive --format=tar --prefix="$PREFIX/" $TREEISH > "$TMPDIR/$(basename $(pwd)).tar"
echo "$TMPDIR/$(basename $(pwd)).tar" >| $TMPFILE
superfile=$(head -n 1 $TMPFILE)

find . -name '.git' -type d -print | sed -e 's/^\.\///' -e 's/\.git$//' | grep -v '^$' >> $TOARCHIVE

while read path; do
    TREEISH=$(git submodule | grep "^ .*${path%/} " | cut -d ' ' -f 2)
    cd "$path"
    git archive --format=tar --prefix="${PREFIX}/$path" ${TREEISH:-HEAD} > "$TMPDIR"/"$(echo "$path" | sed -e 's/\//./g')"tar
    echo "$TMPDIR"/"$(echo "$path" | sed -e 's/\//./g')"tar >> $TMPFILE
    cd "$OLD_PWD"
done < $TOARCHIVE

if [ $SEPARATE -eq 0 ]; then
    sed -e '1d' $TMPFILE | while read file; do
        tar --concatenate -f "$superfile" "$file"
    done

    echo "$superfile" >| $TMPFILE
fi

cd "$TMPDIR"
tar xf "$superfile"
cd "$PREFIX"
make flat > /dev/null
find ./ -iname '.git*' | xargs rm -f
cd "$TMPDIR"
tar czf "${OUT_FILE}.gz" "${PREFIX}"
