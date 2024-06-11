# OpenSCAD build docker

A docker container for building OpenSCAD

This is the config for building a docker container that will build the OpenSCAD
source code, and allow you to run it from the host or the container.

## Initialize submodule

This repository has a submodule `src` that points to my fork of the OpenSCAD
project. Be sure to initialize the submodule before building the docker image.

```
git submodule update --init --recursive
```

## Build the docker image

```
docker build --progress=plain -t openscad -t openscad:latest .
```

## Run the docker image

Running the docker image will automatically build OpenSCAD. At present, it won't
actually run the resultant built OpenSCAD, but I may add that in the future.

I will provide 3 command lines you can use to run the docker image.
One that builds OpenSCAD and destroys the container all in one fell swoop, and
two others that just set up the container, and you the user need to attach to
the container and initiate the build.

### Building OpenSCAD from a single `docker run` command

This will build OpenSCAD fully automated right from the `docker run` command,
placing the build output on the host in the `openscad-build` directory under the
host directory you bind-mount to /host.

```
docker run -v <some host path>:/host --rm -d openscad:latest
```

If you would like to monitor the build progress, use the `docker logs` command.
You will need to find out the container name using `docker ps`.

```
docker logs -f <container name>
```

NOTE: If you try to attach to the docker container not set up to run
interactively, you will not be able to detach from it using the detach key
sequence. If you do this, open another shell, use `ps` to find the `docker
attach` command you ran, and kill the pid with `kill -9`. If you do this, then
you will get access to your terminal back.

### Run the docker image interactively (optional)

If you would like to perform the OpenSCAD build in the container yourself,
follow this approach. You need to pass the ` -i` and ` -t` options to make an
interactive container connected to a TTY. The `-i` option is provided at the
end of the command line to tell the shell to ignore running the setup script
and instead start an interactive shell within the container.

If you want to have the build directory stored on the host, be sure to
bind-mount a host path to /host in the container. setup.sh will recognize this
and use that as the directory to put the `openscad-build` directory in.
To do that, add `-v <some host path>:/host` (just like in the non-interactive
example) to the below command line.

```
docker run -it --rm -d openscad:latest -i
```

If you would like to build against a version of Qt from an official Qt.io build
of Qt installed with their installer tool, use the below command.

```
docker run -v $HOME/Qt:/home/dev/Qt:ro \
    -v <path to dir with the Dockerfile>:/host -it --rm -d openscad:latest -i
```

If you for some reason want to do a build against a commercial version of Qt,
you will need to bind mount your `$HOME/.local/share/Qt` directory into the
container: `-v $HOME/.local/share/Qt:/home/dev/.local/share/Qt:ro`. Open source
versions of Qt don't need this.

Now, this will not attach to the container by itself, you must call `docker
attach`, passing the name of the container to attach to the container, which
will then put you at a bash prompt from within the container. The build will
not be configured or started for you; Telling docker to run interactively skips
running the `CMD` command. In order to manually start the docker container the
same way that the non-interactive container does, you will need to call
`~/setup.sh`.

To discover the name of the container (that docker auto-generates), run `docker
ps -a`, and look for a container that uses image `openscad:latest`. The name
will be the last field shown, in the form of two random words separated by an
underscore.

To exit the interactive shell, press the default detach key sequence of
CTRL-P,CTRL-Q.

## Running openscad

Once you have openscad built, you may want to test it out. You can do that on
the host side, by setting LD_LIBRARY_PATH to a directory with the Qt libs, as
well as the openscad build directory. As part of setup.sh, once everything is
built, the needed libraries that are not available on the host side (assuming
Ubuntu 23.10) are copied into the openscad-build directory, and launching
openscad, like so:

```
LD_LIBRARY_PATH=$HOME/Qt/5.15.17/gcc_64/lib:$PWD/openscad-build openscad-build/openscad
```

Alternatively, you can run it from within the container. To do so, you need to
run one auth command on your host, and specify a number of additional options on
the `docker run` command line:

Run this on your host:
```
xhost -local:docker
```

For the app to display on the X server:
```
--env="DISPLAY" --env="QT_X11_NO_MITSHM=1" -v /tmp/.X11-unix:/tmp/.X11-unix:rw
```

For PulseAudio to work:
```
--env="XDG_RUNTIME_DIR" -v /dev/shm:/dev/shm -v /etc/machine-id:/etc/machine-id -v /run/user/$UID:/run/user/$UID -v /var/lib/dbus:/var/lib/dbus
```

Example:
```
docker run --env="XDG_RUNTIME_DIR" -v /dev/shm:/dev/shm -v /etc/machine-id:/etc/machine-id -v /run/user/$UID:/run/user/$UID -v /var/lib/dbus:/var/lib/dbus --env="DISPLAY" --env="QT_X11_NO_MITSHM=1" -v /tmp/.X11-unix:/tmp/.X11-unix:rw -v $HOME/.local/share/Qt:/home/dev/.local/share/Qt:ro -v $HOME/Qt:/home/dev/Qt:ro -v $PWD:/host -it --rm -d openscad:latest -i
```
