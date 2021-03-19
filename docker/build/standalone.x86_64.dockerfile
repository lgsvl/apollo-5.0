# Copyright (c) 2021 LG Electronics, Inc. All Rights Reserved

ARG DOCKER_REPO=lgsvl/apollo-5.0
ARG DOCKER_REPO_VOLUME=apolloauto/apollo
ARG TARGET_ARCH=x86_64
ARG IMAGE_VERSION=14.04-5.0-20210319
ARG BASE_IMAGE=${DOCKER_REPO}:runtime-${TARGET_ARCH}-${IMAGE_VERSION}

ARG DOCKER_USER
ARG DOCKER_USER_ID
ARG DOCKER_GRP
ARG DOCKER_GRP_ID

FROM ${DOCKER_REPO_VOLUME}:yolo3d_volume-x86_64-latest as apollo_yolo3d_volume
FROM ${DOCKER_REPO_VOLUME}:localization_volume-x86_64-latest as apollo_localization_volume
FROM ${DOCKER_REPO_VOLUME}:paddlepaddle_volume-x86_64-latest as apollo_paddlepaddle_volume
FROM ${DOCKER_REPO_VOLUME}:local_third_party_volume-x86_64-latest as apollo_local_third_party_volume

FROM ${BASE_IMAGE}

ENV DOCKER_USER=${DOCKER_USER:-apollo}
ENV DOCKER_USER_ID=${DOCKER_USER_ID:-1001}
ENV DOCKER_GRP=${DOCKER_GRP:-apollo}
ENV DOCKER_GRP_ID=${DOCKER_GRP_ID:-1001}

COPY \
    --from=apollo_yolo3d_volume \
    --chown=${DOCKER_USER_ID}:${DOCKER_GRP_ID} \
    /apollo/modules/perception/model/yolo_camera_detector \
    /apollo/modules/perception/model/yolo_camera_detector

COPY \
    --from=apollo_localization_volume \
    --chown=${DOCKER_USER_ID}:${DOCKER_GRP_ID} \
    /usr/local/apollo \
    /usr/local/apollo

COPY \
    --from=apollo_paddlepaddle_volume \
    --chown=${DOCKER_USER_ID}:${DOCKER_GRP_ID} \
    /usr/local/apollo \
    /usr/local/apollo

COPY \
    --from=apollo_local_third_party_volume \
    --chown=${DOCKER_USER_ID}:${DOCKER_GRP_ID} \
    /usr/local/apollo \
    /usr/local/apollo

# copy built apollo and all necessary files prepared in docker/build/output by docker/build/standalone.x86_64.sh
COPY \
    --chown=${DOCKER_USER_ID}:${DOCKER_GRP_ID} \
    output \
    /

RUN /apollo/scripts/docker_adduser.sh
