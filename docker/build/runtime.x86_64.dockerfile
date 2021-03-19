# Copyright (c) 2020 LG Electronics, Inc. All Rights Reserved

# The lgsvl/apollo-5.0 container is huge with almost 10GB size and also needs 4 additional volumes and apollo repository
# after building Apollo inside and including all necessary files inside it becomes approximately 20 GB which is too big
# for use in WISE cloud simulations.

# This runtime image doesn't allow Apollo to be built, but contains all necessary files to just run it.

# The base image itself is quite big:
# lgsvl/apollo-5.0            latest                                         c24e0a4bf5c7        15 months ago       9.83GB
# because it's also based on a big base image:
# apolloauto/apollo           dev-x86_64-20190617_1100                       6b64e2b77e67        15 months ago       9.71GB

# Start from nvidia/cuda:8.0-cudnn7-runtime-ubuntu14.04 instead of 8.0-cudnn7-devel-ubuntu14.04 to save 1GB:
# nvidia/cuda                 8.0-cudnn7-devel-ubuntu14.04                   89a0de517837        13 months ago       2.01GB
# nvidia/cuda                 8.0-cudnn7-runtime-ubuntu14.04                 45c714594daa        13 months ago       1.02GB

FROM nvidia/cuda:8.0-cudnn7-runtime-ubuntu14.04

# Work around gnutls_handshake() failed: Handshake failed from ubuntu 14.04
RUN sed -i 's/https:/http:/g' /etc/apt/sources.list.d/nvidia-ml.list /etc/apt/sources.list.d/cuda.list

# docker/build/installers/install_apollo_files.txt explains why these packages are needed
# the order of packages matches with the list there
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y \
    --no-install-recommends \
    libx11-6 \
    libgomp1 \
    libopenmpi1.6 \
    libopenblas-base \
    libopencv-core2.4 \
    libboost-system1.54.0 \
    libboost-signals1.54.0 \
    libboost-thread1.54.0 \
    libpocofoundation9 \
    libatomic1 \
    python \
    curl \
    libopencv-highgui2.4 \
    libboost-filesystem1.54.0 \
    libboost-iostreams1.54.0 \
    libboost-chrono1.54.0 \
    libvtk5.8 \
    libpcap0.8 \
    libqhull6 \
    libsnappy1 \
    ocl-icd-libopencl1 \
    libboost-program-options1.54.0 \
    libatlas3-base \
    cuda-command-line-tools-8-0 \
    libvtk5.8-qt4 \
    libpython2.7 \
    liblapack3 \
    python3-psutil \
    python-yaml \
    libxcb-shape0 \
    libxcb-xfixes0 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=nvidia/opengl:1.1-glvnd-runtime-ubuntu14.04 \
 /usr/local/lib/x86_64-linux-gnu \
 /usr/local/lib/x86_64-linux-gnu

COPY --from=nvidia/opengl:1.1-glvnd-runtime-ubuntu14.04 \
 /usr/local/share/glvnd/egl_vendor.d/10_nvidia.json \
 /usr/local/share/glvnd/egl_vendor.d/10_nvidia.json

RUN echo '/usr/local/lib/x86_64-linux-gnu' >> /etc/ld.so.conf.d/glvnd.conf && \
 ldconfig && \
 echo '/usr/local/$LIB/libGL.so.1' >> /etc/ld.so.preload && \
 echo '/usr/local/$LIB/libEGL.so.1' >> /etc/ld.so.preload

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES ${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES ${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics

RUN ldconfig
