#!/bin/bash
set -e -u

cd $HOME 

./build.sh

builddir="$HOME/openscad-build"
if [[ -e /host ]]; then
    builddir="/host/openscad-build"
fi

echo
echo "Build finished. OpenSCAD build located in $builddir"

set +u
if [[ -z "$DISPLAY" ]]; then
    set -u
    echo
    echo >&2 'Container does not have sufficient `docker run` arguments to launch OpenSCAD'
    echo >&2 'To run, provide the following additional options to `docker run`:'
    echo >&2 '    --env="XDG_RUNTIME_DIR" -v /dev/shm:/dev/shm -v /etc/machine-id:/etc/machine-id -v /run/user/$UID:/run/user/$UID -v /var/lib/dbus:/var/lib/dbus --env="DISPLAY" --env="QT_X11_NO_MITSHM=1" -v /tmp/.X11-unix:/tmp/.X11-unix:rw'
    exit 1
fi

set -u
echo "Attempting to start openscad"
cd $builddir
set +e
./openscad
ret=$?
set -e
if [[ $ret -ne 0 ]]; then
    echo >&2
    echo >&2 -e "It looks like openscad crashed. This is likely" \
        "because you built with\nthe Qt that comes with the base container" \
        "(from debian bookworm)"
    echo >&2
    echo >&2 -e "Try downloading the Qt installer from qt.io, install the" \
        "latest Qt 5.15 release\non your host. It will default the" \
        'installation to $HOME/Qt.'
    echo >&2
    echo >&2 'Then, add the following to your `docker run` command line:'
    echo >&2 '    `-v $HOME/.local/share/Qt:/home/dev/.local/share/Qt:ro -v' \
        '$HOME/Qt:/home/dev/Qt:ro`'
fi
