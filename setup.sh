#!/bin/bash

# Copy over the debs that were installed, so that future docker build commands
# won't re-fetch the debs.
md5sum --status -c /var-cache-apt-archives.tar.md5
res=$?
if [[ -d /host && $res -ne 0 ]]; then
    cp /var-cache-apt-archives.tar /host
fi

BUILDDIR=$HOME/openscad-build
if [ -e /host ]; then
    if [ ! -d /host ]; then
        echo >&2 "error: /host exists but is not a directory"
	echo >&2 "aborting."
	exit 1
    fi
    BUILDDIR=/host/openscad-build
fi
if [[ -e $BUILDDIR && ! -d $BUILDDIR ]]; then
    echo >&2 "error: `$BUILDDIR` exists but is not a directory"
    echo >&2 "aborting."
    exit 1
fi
mkdir -p $BUILDDIR

# If the container was set up with commercial Qt bind mounted into the
# container, set things up to use it.
qtdir="$HOME/Qt/5.15.17/gcc_64"
if [[ -d "$qtdir" ]]; then
    export PATH="$qtdir/bin":$PATH
    export CMAKE_PREFIX_PATH=$qtdir

    # Validate that Qt license keys are present.
    if [[ ! -f "$HOME/.local/share/Qt/qtlicenses.ini" ]]; then
        echo >&2 \
"error: Commercial Qt was bind-mounted into the container, but no Qt license"
"keys\nare present"
        echo >&2 "aborting."
        exit 2
    fi
fi

# Build qscintilla
cd /sources
export NUMCPU=16
scripts/uni-build-dependencies.sh qt5scintilla2
ret=$?
if [ $ret -eq 0 ]; then
    echo "Successfully built qt5scintilla2"
else
    echo >&2 "Failed to build qt5scintilla2 - return code $ret"
fi

# Build OpenSCAD
cd $BUILDDIR
cmake /sources -DEXPERIMENTAL=1 -DOPENSCAD_DEPS=$HOME/openscad_deps
make -j${NUMCPU}

cp -L /usr/lib/x86_64-linux-gnu/libopencsg.so.1 $BUILDDIR
cp -L /usr/lib/x86_64-linux-gnu/libzip.so.4 $BUILDDIR
