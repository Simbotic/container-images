#!/usr/bin/env bash

RUN_PROD=$1

if [ "$RUN_PROD" = "p" ]
then
    echo "===> production"
    docker build -t simbotic-sim ./production
else
    echo "===> base"
    docker build -t simbotic ./base
fi