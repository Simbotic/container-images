#!/usr/bin/env bash

RUN_PROD=$1

if [ "$RUN_PROD" = "p" ]
then
    echo "===> production"
    docker run \
        -ti \
        --gpus all \
        --device /dev/snd \
        --cap-add=SYS_PTRACE \
        --security-opt seccomp=unconfined \
        --name simbotic-sim \
        -e DISPLAY="${DISPLAY}" \
        -e PULSE_SERVER=unix:"${XDG_RUNTIME_DIR}"/pulse/native \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        -v "${XDG_RUNTIME_DIR}"/pulse/native:"${XDG_RUNTIME_DIR}"/pulse/native \
        simbotic-sim bash
else
    echo "===> development"
    docker run \
        -ti \
        --gpus all \
        --device /dev/snd \
        --cap-add=SYS_PTRACE \
        --security-opt seccomp=unconfined \
        --name simbotic \
        -e DISPLAY="${DISPLAY}" \
        -e PULSE_SERVER=unix:"${XDG_RUNTIME_DIR}"/pulse/native \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        -v "${XDG_RUNTIME_DIR}"/pulse/native:"${XDG_RUNTIME_DIR}"/pulse/native \
        simbotic bash
fi
