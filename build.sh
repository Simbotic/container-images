#!/usr/bin/env bash

RUN_PROD=$1

if [ "$RUN_PROD" = "p" ]
then
    echo "===> production"
    docker build --target production-stage -t simbotic-sim ./simbotic
else
    echo "===> development"
    docker build --target cook-stage -t simbotic ./simbotic
    # to invalidate cache
    # docker build --build-arg DATE_OPT="$(date +%s)" --target cook-stage -t simbotic ./simbotic
fi
