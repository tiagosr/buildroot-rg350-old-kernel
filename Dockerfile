FROM ubuntu:jammy AS build

ENV DEBIAN_FRONTEND noninteractive

RUN apt update && \
    apt install -y \
        bash \
        bc gettext ccache file \
        build-essential g++ gcc binutils \
        cpio \
        wget \
        zip unzip bzip2 gzip tar unrar-free \
        git mercurial subversion \
        python2 python3 \
        time \
        automake autoconf \
        make rsync cmake \
        squashfs-tools dosfstools mtools \
        libz-dev libncurses5-dev && \
    apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /work/
COPY arch/ /work/arch/
COPY board/ /work/board/
COPY boot/ /work/boot/
COPY configs/ /work/configs/
COPY docs/ /work/docs/
COPY fs/ /work/fs/
COPY linux/ /work/linux/
COPY opks/ /work/opks/
COPY package/ /work/package/
COPY support/ /work/support/
COPY system/ /work/system/
COPY toolchain/ /work/toolchain/
COPY utils/ /work/utils/
COPY Config.in Config.in.legacy Makefile Makefile.legacy /work/
ENV FORCE_UNSAFE_CONFIGURE=1

RUN ln -s /usr/bin/python2 /usr/bin/python

# RUN /bin/bash
RUN git config --global url."https://github.com/".insteadOf git://github.com/
RUN make rg350_defconfig BR2_EXTERNAL=board/opendingux:opks BR2_PACKAGE_HOST_ENVIRONMENT_SETUP=y BR2_JLEVEL=0 O=output
RUN make prepare-sdk BR2_JLEVEL=0 O=output
RUN rm -rf /work/output/build
RUN rm -rf /work/dl

# --------------

# RUN /work/board/opendingux/gcw0/make_initial_image.sh rg350m
# RUN make sdk O=output-rg350m

# RUN /work/board/opendingux/gcw0/make_initial_image.sh rg280v
# RUN make sdk O=output-rg280v

# --------------

FROM ubuntu:jammy

ENV DEBIAN_FRONTEND noninteractive

RUN apt update && \
    apt install -y \
        bash \
        bc gettext ccache \
        build-essential \
        cpio \
        wget \
        zip unzip bzip2 gzip tar unrar-free \
        git mercurial subversion \
        python2 python3 \
        time \
        automake autoconf \
        make rsync cmake scons \
        squashfs-tools dosfstools mtools \
        libz-dev libncurses5-dev && \
    apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=build /work/output/host/ /opt/opendingux-toolchain/
RUN /opt/opendingux-toolchain/relocate-sdk.sh
RUN echo "source /opt/opendingux-toolchain/environment-setup" >> /root/.bashrc

WORKDIR /work
RUN git clone --recurse-submodules https://github.com/libpd/libpd.git
RUN git clone https://github.com/PortMidi/portmidi.git

WORKDIR /work/libpd
RUN make CC=/opt/opendingux-toolchain/bin/mipsel-linux-gcc CXX=/opt/opendingux-toolchain/bin/mipsel-linux-g++ STATIC=true
RUN make CC=/opt/opendingux-toolchain/bin/mipsel-linux-gcc CXX=/opt/opendingux-toolchain/bin/mipsel-linux-g++ STATIC=true prefix=/opt/opendingux-toolchain/mipsel-rg350-linux-uclibc/sysroot/usr install

WORKDIR /work/portmidi
RUN /usr/bin/bash -c "source /opt/opendingux-toolchain/environment-setup ; cmake CC=mipsel-linux-gcc CXX=mipsel-linux-g++ BUILD_SHARED_LIBS=OFF CMAKE_INSTALL_PREFIX=/opt/opendingux-toolchain . ; make && make install"

WORKDIR /src
CMD /usr/bin/bash -l