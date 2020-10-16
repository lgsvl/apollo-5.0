#!/bin/bash

# Copyright (c) 2020 LG Electronics, Inc. All Rights Reserved

set -e

if [ "$1" == "rebuild" ] ; then
  DEV_START__BUILD_ONLY__LGSVL=1 docker/scripts/dev_start.sh
  docker exec -u $USER -t apollo_dev_$USER bazel clean --expunge || true
  docker exec -u $USER -t apollo_dev_$USER /apollo/apollo.sh build_opt_gpu
fi

# Expects that the Apollo was already built in apollo_dev_$USER
if ! docker exec -u $USER -t apollo_dev_$USER ls /apollo/bazel >/dev/null; then
  echo "ERROR: apollo_dev_$USER isn't running or doesn't have /apollo/bazel directory"
  echo "       make sure it's running (you can use docker/scripts/dev_start.sh)"
  echo "       and build Apollo there or add \"rebuild\" parameter to this script"
  echo "       and it will be started and built automatically"
  exit 1
fi

docker build -f docker/build/runtime.x86_64.dockerfile docker/build/ -t lgsvl/apollo-5.0-runtime

docker stop apollo_runtime_$USER || true
docker rm apollo_runtime_$USER || true
docker run -it -d --name apollo_runtime_$USER lgsvl/apollo-5.0-runtime /bin/bash
docker commit -m "Without prebuilt files" apollo_runtime_$USER

# Copy the contents of pcl 1.7.2 built without avx2
docker build -f docker/build/nvidia.dockerfile docker/build/ -t lgsvl/apollo-5.0-pcl
docker run lgsvl/apollo-5.0-pcl sh -c 'tar -cf - /usr/local/lib/libpcl_*.so.*' | docker cp -a - apollo_runtime_$USER:/

# Copy apollo repository
docker exec apollo_runtime_$USER mkdir /apollo
docker exec apollo_runtime_$USER mkdir /usr/local/apollo
tar -cf - --exclude ./bazel/install --exclude=./modules/map/data/* --exclude=./data/log/* --exclude=**/.git --exclude=**/_objs --exclude=**/*.a --exclude=./lgsvlsimulator-output . | docker cp -a - apollo_runtime_$USER:/apollo

grep -v ^# docker/build/installers/install_apollo_files.txt > docker/build/installers/install_apollo_files.txt.tmp
docker exec apollo_dev_$USER sh -c 'tar -C / -cf - --files-from=/apollo/docker/build/installers/install_apollo_files.txt.tmp' | docker cp -a - apollo_runtime_$USER:/
rm -f docker/build/installers/install_apollo_files.txt.tmp

# Copy in the contents of the mounted volumes.
# dev container contains following volumes:
# apolloauto/apollo           yolo3d_volume-x86_64-latest                    6a9cbf71163e        2 years ago         275MB
# apolloauto/apollo           localization_volume-x86_64-latest              109001137d4a        15 months ago       5.44MB
# apolloauto/apollo           paddlepaddle_volume-x86_64-latest              1f96e81c6a99        15 months ago       804MB
# apolloauto/apollo           local_third_party_volume-x86_64-latest         5df2bf3cc4b9        16 months ago       156MB

# apolloauto/apollo:local_third_party_volume-x86_64-latest
docker cp apollo_local_third_party_volume_$USER:/usr/local/apollo/local_third_party - | docker cp -a - apollo_runtime_$USER:/usr/local/apollo

# apolloauto/apollo:paddlepaddle_volume-x86_64-latest
docker cp apollo_paddlepaddle_volume_$USER:/usr/local/apollo/paddlepaddle - | docker cp -a - apollo_runtime_$USER:/usr/local/apollo
docker cp apollo_paddlepaddle_volume_$USER:/usr/local/apollo/paddlepaddle_dep - | docker cp -a - apollo_runtime_$USER:/usr/local/apollo

# apolloauto/apollo:localization_volume-x86_64-latest
docker cp apollo_localization_volume_$USER:/usr/local/apollo/local_integ - | docker cp -a - apollo_runtime_$USER:/usr/local/apollo

# apolloauto/apollo:yolo3d_volume-x86_64-latest
docker cp apollo_yolo3d_volume_$USER:/apollo/modules/perception/model/yolo_camera_detector/lane13d_0716 - | docker cp -a - apollo_runtime_$USER:/apollo/modules/perception/model/yolo_camera_detector
docker cp apollo_yolo3d_volume_$USER:/apollo/modules/perception/model/yolo_camera_detector/lane2d_0627 - | docker cp -a - apollo_runtime_$USER:/apollo/modules/perception/model/yolo_camera_detector
docker cp apollo_yolo3d_volume_$USER:/apollo/modules/perception/model/yolo_camera_detector/yolo3d_1128 - | docker cp -a - apollo_runtime_$USER:/apollo/modules/perception/model/yolo_camera_detector

docker exec apollo_runtime_$USER ldconfig

cat <<! > image-info-lgsvl.source
IMAGE_APP=apollo-5.0
IMAGE_CREATED_BY=runtime.x86_64.sh
IMAGE_CREATED_FROM=$(git describe --tags --always)
IMAGE_CREATED_ON=$(date --iso-8601=seconds --utc)
# Increment IMAGE_INTERFACE_VERSION whenever changes to the image require that the launcher be updated.
IMAGE_INTERFACE_VERSION=1
IMAGE_UUID=$(uuidgen)
!

docker cp image-info-lgsvl.source apollo_runtime_$USER:/apollo/image-info-lgsvl.source
rm -f image-info-lgsvl.source

docker commit -m "With prebuilt files" apollo_runtime_$USER lgsvl/apollo-5.0-runtime:latest

/bin/echo -e "Docker image with prebuilt files was built and tagged as lgsvl/apollo-5.0-runtime:latest, you can start it with: \n\
  docker/scripts/runtime_start.sh\n\
and switch into it with:\n\
  docker/scripts/runtime_into.sh"
