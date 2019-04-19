FROM apolloauto/apollo:dev-x86_64-20190307_1502

# nvidia runtime

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

# compile and include libpcl 1.7.2 without avx2

COPY patch/*.patch /tmp/

RUN set -eu \
    && cd /mnt \
    && wget -q -O - https://github.com/PointCloudLibrary/pcl/archive/pcl-1.7.2.tar.gz | tar -xz \
    && cd pcl-pcl-1.7.2 \
    && patch -i /tmp/libpcl-cxx11.patch \
    && patch -p 1 -i /tmp/libpcl-remove-native-march.patch \
    && mkdir build \
    && cd build \
    && cmake .. -DCMAKE_BUILD_TYPE=Release \
    && make -j`nproc` \
    && make install \
    && ldconfig \
    && rm -rf /mnt/pcl-pcl-1.7.2
