#!/bin/bash

# Copyright (c) 2020-2021 LG Electronics, Inc. All Rights Reserved

DOCKER_REPO=lgsvl/apollo-5.0
TARGET_ARCH=x86_64
IMAGE_VERSION=14.04-5.0-20210319
DEV_IMAGE=${DOCKER_REPO}:dev-${TARGET_ARCH}-${IMAGE_VERSION}
PCL_IMAGE=${DOCKER_REPO}:pcl-${TARGET_ARCH}-${IMAGE_VERSION}
RUNTIME_IMAGE=${DOCKER_REPO}:runtime-${TARGET_ARCH}-${IMAGE_VERSION}
STANDALONE_IMAGE=${DOCKER_REPO}:standalone-${TARGET_ARCH}-${IMAGE_VERSION}
STANDALONE_IMAGE_LATEST=${DOCKER_REPO}:standalone-${TARGET_ARCH}-14.04-5.0-latest

set -e

if [ "$1" == "rebuild" ] ; then
  DEV_START__BUILD_ONLY__LGSVL=1 docker/scripts/dev_start.sh
  docker exec -u $USER -t apollo_5.0_dev_$USER bazel clean --expunge || true
  docker exec -u $USER -t apollo_5.0_dev_$USER /apollo/apollo.sh build_opt_gpu
fi

# Expects that the Apollo was already built in apollo_5.0_dev_$USER
if ! docker exec -u $USER -t apollo_5.0_dev_$USER ls /apollo/.cache/bazel >/dev/null; then
  echo "ERROR: apollo_5.0_dev_$USER isn't running or doesn't have /apollo/.cache/bazel directory"
  echo "       make sure it's running (you can use docker/scripts/dev_start.sh)"
  echo "       and build Apollo there or add \"rebuild\" parameter to this script"
  echo "       and it will be started and built automatically"
  exit 1
fi

rm -rf docker/build/output

# Copy the contents of pcl 1.7.2 built without avx2
docker build \
    -f docker/build/nvidia.dockerfile \
    docker/build/ \
    -t ${PCL_IMAGE}
mkdir -p docker/build/output
docker run --rm ${PCL_IMAGE} sh -c 'tar -cf - /usr/local/lib/libpcl_*.so.*' | tar xf - -C docker/build/output/

docker build \
    -f docker/build/runtime.x86_64.dockerfile \
    docker/build/ \
    -t ${RUNTIME_IMAGE}

# Copy the built output into "output" direcotry
mkdir -p docker/build/output/apollo
tar -cf - --exclude ./docker/build/output --exclude ./.cache/bazel/install --exclude=./modules/map/data/* --exclude=./data/log/* --exclude=**/.git --exclude=**/_objs --exclude=**/*.a --exclude=./lgsvlsimulator-output . | tar xf - -C docker/build/output/apollo

grep -v ^# docker/build/installers/install_apollo_files.txt > docker/build/installers/install_apollo_files.txt.tmp
docker exec apollo_5.0_dev_$USER sh -c 'tar -C / -cf - --files-from=/apollo/docker/build/installers/install_apollo_files.txt.tmp' | tar xf - -C docker/build/output/
rm -f docker/build/installers/install_apollo_files.txt.tmp

# Add the startup scripts, so that they could be extracted from image you pull with docker
# docker run --rm ${STANDALONE_IMAGE} sh -c 'tar -cf - -C /apollo standalone-scripts' | tar -xf -
mkdir -p docker/build/output/apollo/standalone-scripts/docker/scripts
cp docker/scripts/runtime_start.sh docker/scripts/runtime_into_standalone.sh docker/build/output/apollo/standalone-scripts/docker/scripts
mkdir -p docker/build/output/apollo/standalone-scripts/scripts
cp scripts/apollo_base.sh docker/build/output/apollo/standalone-scripts/scripts

cat <<! > docker/build/output/apollo/image-info-lgsvl.source
IMAGE_APP=apollo-5.0
IMAGE_CREATED_BY=standalone.x86_64.sh
IMAGE_CREATED_FROM=$(git describe --tags --always)
IMAGE_CREATED_ON=$(date --iso-8601=seconds --utc)
# Increment IMAGE_INTERFACE_VERSION whenever changes to the image require that the launcher be updated.
IMAGE_INTERFACE_VERSION=2
IMAGE_UUID=$(uuidgen)
!

docker build \
    -f docker/build/standalone.x86_64.dockerfile \
    docker/build/ \
    -t ${STANDALONE_IMAGE}

docker tag ${STANDALONE_IMAGE} ${STANDALONE_IMAGE_LATEST}

/bin/echo -e "Docker image with prebuilt files was built and tagged as ${STANDALONE_IMAGE}, you can start it with: \n\
  docker/scripts/runtime_start.sh\n\
and switch into it with:\n\
  docker/scripts/runtime_into_standalone.sh"
