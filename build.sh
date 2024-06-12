#!/bin/bash

set -e -u

# Function to handle errors
error_handler() {
    echo "Error occurred in script $0 at line: $1"
}

# Set the trap to call error_handler on ERR
trap 'error_handler $LINENO' ERR

# Set the number of simultaneous compile jobs to perform when building.
# This is set to the number of CPUs detected minus 2 (so the container doesn't
# monopolize all of the processors and hyperthreads)
export NPARALLEL=$(cat /proc/cpuinfo | awk ' BEGIN { nprocs=0 } /^processor/ { nprocs=$3+1 } END { print nprocs-2 }')

function find_latest_installed_qt_version() {
    set +e
    readarray -t qt_versions < <(cd ~/Qt; ls -1d [5]*/ | awk -F'/' '{print $1}' | sort -V)
    set -e
    LATEST_INSTALLED_QT_VERSION=${qt_versions[$((${#qt_versions}-1))]}
}

# Copy over the debs that were installed, so that future docker build commands
# won't re-fetch the debs.
if [[ -d /host ]] && ! md5sum --status -c /var-cache-apt-archives.tar.md5; then
    echo "Copying over apt cache tarball to the host"
    cp /var-cache-apt-archives.tar /host
else
    echo "Host's apt cache tarball doesn't need updating, skipping copy."
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

# If the container was set up with a Qt installer installed version of Qt bind
# mounted into the container, set things up to use it.
if [[ -d $HOME/Qt ]]; then
    find_latest_installed_qt_version

    qtdir="$HOME/Qt/${LATEST_INSTALLED_QT_VERSION}/gcc_64"
    if [[ ! -d "$qtdir" ]]; then
        echo >&2 "Your $qtdir directory seems to be broken. I found a Qt version to use, but it doesn't actually seem to contain a Qt build"
        echo >&2 "aborting."
        exit 2
    fi

    echo "Latest Qt5 install found is $qtdir. Using it."
    export PATH="$qtdir/bin":$PATH
    export CMAKE_PREFIX_PATH=$qtdir

    # Check if Qt license keys are present, and warn if not. It may still work
    # if it is an OSS version of Qt, so don't bail, just warn.
    if [[ ! -f "$HOME/.local/share/Qt/qtlicenses.ini" ]]; then
        echo -e >&2 "warning: A qt.io build of Qt was bind-mounted into the" \
            "container, but no Qt\nlicense keys are present."
        echo >&2 "If this is a commercial version of Qt, the project will" \
            "fail to build."
    fi
fi

# Build qscintilla
cd /sources
# uni-build-dependencies.sh allows you to specify the # parallel builds it does
# by setting the env var `NUMCPU` - which we set at the top of this script.
export NUMCPU=$NPARALLEL
if scripts/uni-build-dependencies.sh qt5scintilla2; then
    echo "Successfully built qt5scintilla2"
else
    echo >&2 "Failed to build qt5scintilla2 - return code $?"
    exit 3
fi

# Build OpenSCAD
cd $BUILDDIR
cmake /sources -DEXPERIMENTAL=1 -DOPENSCAD_DEPS=$HOME/openscad_deps
make -j${NUMCPU}

# Copy over the shaders to the build directory, as they are needed for running.
cp -a /sources/shaders $BUILDDIR

# Copy over a couple of libs from the container into the build directory so that
# it can be run on the host (host still needs to provide Qt).
cp -L /usr/lib/x86_64-linux-gnu/libopencsg.so.1 $BUILDDIR
cp -L /usr/lib/x86_64-linux-gnu/libzip.so.4 $BUILDDIR
