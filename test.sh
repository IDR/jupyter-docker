#!/bin/sh

IDR_IMAGE=${IDR_IMAGE:-test-jupyter-docker}

set -eu
set -x
docker rm -f ${IDR_IMAGE} || true
docker build -t ${IDR_IMAGE} .
docker run -d --name ${IDR_IMAGE} \
    -e IDR_HOST="$IDR_HOST" \
    -e IDR_USER="$IDR_USER" \
    -e IDR_PASSWORD="$IDR_PASSWORD" \
    ${IDR_IMAGE}
docker cp test_notebooks.py ${IDR_IMAGE}:/
docker exec ${IDR_IMAGE} /opt/conda/envs/python2/bin/pytest "$@" /test_notebooks.py
