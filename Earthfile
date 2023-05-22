VERSION 0.7

FROM library/alpine:3.18

COPY_SELF:
  COMMAND
  COPY --if-exists ./output/*.* ./output
  COPY --dir --if-exists ./output/dl ./dl
  COPY --dir --if-exists ./output/ccache ./ccache

SAVE_SELF:
  COMMAND
  ARG output
  SAVE ARTIFACT --if-exists ./output/*.* AS LOCAL ./output/
  # FOR dir IN $(ls -d ./output/*)
  #   IF [ -d $dir ]
  #     RUN base=$(basename $dir)
  #     RUN echo ">>>> $base"
  #     IF [ "$base" = "images" ]
  #       RUN echo "SAVE ARTIFACT --if-exists ./output/$base/* AS LOCAL ./output/$base/"
  #       SAVE ARTIFACT --if-exists ./output/$base/* AS LOCAL ./output/$base/
  #     # ELSE
  #     END
  #   END
  # END
  # IF [ -d ./output ]
  #   RUN ls -d ./output/*
  # END

  # IF [ -d ./output/images ]
  #   RUN ls -d ./output/images/*
  # END

  SAVE ARTIFACT --if-exists ./output/images/* AS LOCAL ./output/images/
  SAVE ARTIFACT --if-exists ./dl/* AS LOCAL ./output/dl/
  SAVE ARTIFACT --if-exists ./ccache/* AS LOCAL ./output/ccache/
  SAVE ARTIFACT --if-exists ./.config AS LOCAL ./output/buildroot.config
  SAVE ARTIFACT --if-exists ./defconfig AS LOCAL ./output/buildroot.defconfig

  # build
  # host
  # images
  # staging
  # target

docker-base-1:
  # FROM ailispaw/ubuntu-essential:16.04-nodoc
  # FROM ailispaw/ubuntu-essential:18.04-nodoc

  ARG CODENAME=xenial
  ARG REVISION=20210804
  # ARG CODENAME=bionic
  # ARG REVISION=20220531

  FROM ubuntu:${CODENAME}-${REVISION}
  # 16
  # Make an exception for apt: it gets deselected, even though it probably shouldn't.
  RUN export DEBIAN_FRONTEND=noninteractive && \
      dpkg --clear-selections && \
      echo "apt install" | dpkg --set-selections && \
      apt-get --purge -y dselect-upgrade && \
      apt-get purge -y --allow-remove-essential init systemd && \
      apt-get purge -y libapparmor1 libcap2 libcryptsetup4 libdevmapper1.02.1 libkmod2 libseccomp2 && \
      apt-get --purge -y autoremove && \
      dpkg-query -Wf '\${db:Status-Abbrev}\t\${binary:Package}\n' | \
        grep '^.i' | awk -F'\t' '{print \$2 " install"}' | dpkg --set-selections && \
      rm -rf /var/cache/apt /var/lib/apt/lists /var/cache/debconf/* /var/log/*
  # 18
  # # Make an exception for apt: it gets deselected, even though it probably shouldn't.
  # RUN export DEBIAN_FRONTEND=noninteractive && \
  #     dpkg --clear-selections && \
  #     echo "apt install" | dpkg --set-selections && \
  #     echo "mount install" | dpkg --set-selections && \
  #     apt-get --purge -y dselect-upgrade && \
  #     dpkg-query -Wf '\${db:Status-Abbrev}\t\${binary:Package}\n' | \
  #       grep '^.i' | awk -F'\t' '{print \$2 " install"}' | dpkg --set-selections && \
  #     rm -rf /var/cache/apt /var/lib/apt/lists /var/cache/debconf/* /var/log/*

docker-base-2:
  FROM +docker-base-1

  # https://github.com/kubernetes/contrib/blob/master/images/ubuntu-slim/Dockerfile.build#L28-L50
  RUN cd /usr/share && \
      tar zcf copyrights.tar.gz common-licenses doc/*/copyright && \
      rm -rf common-licenses doc man groff info lintian linda locale

  # https://wiki.ubuntu.com/ReducingDiskFootprint
  RUN echo 'path-exclude /usr/share/doc/*'            > /etc/dpkg/dpkg.cfg.d/01_nodoc && \
      echo 'path-include /usr/share/doc/*/copyright' >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
      echo 'path-exclude /usr/share/man/*'           >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
      echo 'path-exclude /usr/share/groff/*'         >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
      echo 'path-exclude /usr/share/info/*'          >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
      echo 'path-exclude /usr/share/lintian/*'       >> /etc/dpkg/dpkg.cfg.d/01_nodoc && \
      echo 'path-exclude /usr/share/linda/*'         >> /etc/dpkg/dpkg.cfg.d/01_nodoc

docker-base-3:
  # FROM ubuntu:xenial-20210804
  # FROM ubuntu:bionic-20220531
  FROM ailispaw/ubuntu-essential:16.04-nodoc
  # FROM ailispaw/ubuntu-essential:16.04

docker-base:
  # FROM DOCKERFILE \
  #   .  
  FROM +docker-base-3

  ARG TERM=xterm
  ARG SYSLINUX_SITE=https://mirrors.edge.kernel.org/ubuntu/pool/main/s/syslinux
  ARG SYSLINUX_VERSION=4.05+dfsg-6+deb8u1
  # ARG SYSLINUX_VERSION=6.03+dfsg1-2

  ENV DEBIAN_FRONTEND=noninteractive
  RUN set -x \
      && apt-get --assume-yes update \
      && apt-get --assume-yes upgrade \
      && apt-get --assume-yes install --no-install-recommends \
        ca-certificates \
        bc build-essential cpio file git python unzip rsync wget \
        syslinux syslinux-common isolinux xorriso dosfstools mtools \
        python3 jq \
      && wget -q "${SYSLINUX_SITE}/syslinux-common_${SYSLINUX_VERSION}_all.deb" \
      && wget -q "${SYSLINUX_SITE}/syslinux_${SYSLINUX_VERSION}_amd64.deb" \
      && dpkg -i "syslinux-common_${SYSLINUX_VERSION}_all.deb" \
      && dpkg -i "syslinux_${SYSLINUX_VERSION}_amd64.deb" \
      && rm -f "syslinux-common_${SYSLINUX_VERSION}_all.deb" \
      && rm -f "syslinux_${SYSLINUX_VERSION}_amd64.deb" \
      && apt-get clean \
      && rm -rf /var/cache/apt/* /var/lib/apt/lists/* /var/cache/debconf/* /var/log/*

  # Setup environment
  ARG SRC_DIR=/build
  ARG OVERLAY=/overlay
  ARG BR_ROOT=/build/buildroot
  RUN mkdir -p ${SRC_DIR} ${OVERLAY}

  ARG BR_VERSION=2022.05
  # ARG BR_VERSION=2023.02.1
  RUN wget -qO- https://buildroot.org/downloads/buildroot-${BR_VERSION}.tar.xz | tar xJ && \
      mv buildroot-${BR_VERSION} ${BR_ROOT}

  # Apply patches
  COPY patches ${SRC_DIR}/patches
  RUN for patch in ${SRC_DIR}/patches/*.patch; do \
        patch -p1 -d ${BR_ROOT} < ${patch}; \
      done

  # Setup overlay
  COPY overlay ${OVERLAY}
  WORKDIR ${OVERLAY}

  # Add ca-certificates
  RUN mkdir -p etc/ssl/certs && \
      cp /etc/ssl/certs/ca-certificates.crt etc/ssl/certs/

  # Add bash-completion
  RUN mkdir -p usr/share/bash-completion/completions && \
      wget -qO usr/share/bash-completion/bash_completion https://raw.githubusercontent.com/scop/bash-completion/master/bash_completion && \
      chmod +x usr/share/bash-completion/bash_completion

  # Add Docker
  ARG DOCKER_VERSION=1.10.3
  ARG DOCKER_REVISION=barge.2
  RUN mkdir -p usr/bin && \
      wget -qO- https://github.com/bargees/moby/releases/download/v${DOCKER_VERSION}-${DOCKER_REVISION}/docker-${DOCKER_VERSION}-${DOCKER_REVISION}.tar.xz | tar xJ -C usr/bin

  # Add Docker bash-completion
  RUN wget -qO usr/share/bash-completion/completions/docker https://raw.githubusercontent.com/moby/moby/v${DOCKER_VERSION}/contrib/completion/bash/docker

  # Add dumb-init
  ARG DINIT_VERSION=1.2.5
  RUN mkdir -p usr/bin && \
      wget -qO usr/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v${DINIT_VERSION}/dumb-init_${DINIT_VERSION}_x86_64 && \
      chmod +x usr/bin/dumb-init

  ARG VERSION=2.15.0
  RUN mkdir -p etc && \
      echo "Welcome to Barge ${VERSION}, Docker version ${DOCKER_VERSION}" > etc/motd && \
      echo "NAME=\"Barge\"" > etc/os-release && \
      echo "VERSION=${VERSION}" >> etc/os-release && \
      echo "ID=barge" >> etc/os-release && \
      echo "ID_LIKE=busybox" >> etc/os-release && \
      echo "VERSION_ID=${VERSION}" >> etc/os-release && \
      echo "PRETTY_NAME=\"Barge ${VERSION}\"" >> etc/os-release && \
      echo "HOME_URL=\"https://github.com/bargees/barge-os\"" >> etc/os-release && \
      echo "BUG_REPORT_URL=\"https://github.com/bargees/barge-os/issues\"" >> etc/os-release

  # Add Package Installer
  RUN wget -qO usr/bin/pkg https://raw.githubusercontent.com/bargees/barge-pkg/master/pkg && \
      chmod +x usr/bin/pkg

  # Copy config files
  COPY configs ${SRC_DIR}/configs
  RUN cp ${SRC_DIR}/configs/buildroot.config ${BR_ROOT}/.config && \
      cp ${SRC_DIR}/configs/busybox.config ${BR_ROOT}/package/busybox/busybox.config

  COPY scripts ${SRC_DIR}/scripts

  VOLUME ${BR_ROOT}/dl ${BR_ROOT}/ccache

  WORKDIR ${BR_ROOT}
  # CMD ["../scripts/build.sh"]


docker:
  FROM +docker-base
  
  # RUN sed -i -E 's/(archive|security).ubuntu.com/mirrors.163.com/g' /etc/apt/sources.list
  ENV DEBIAN_FRONTEND=noninteractive
  RUN set -x \
      && apt-get --assume-yes update \
      # && apt-get --assume-yes upgrade \
      && apt-get --assume-yes install --no-install-recommends \
      python3 jq \
      && apt-get clean \
      && rm -rf /var/cache/apt/* /var/lib/apt/lists/* /var/cache/debconf/* /var/log/*

losetup:
  FROM --allow-privileged +docker
  RUN --privileged losetup -a
  RUN --privileged losetup -f
  # RUN --privileged make --quiet

source:
  FROM --allow-privileged +docker

  RUN make oldconfig;

  DO +COPY_SELF

  RUN make show-info | jq --raw-output --sort-keys 'keys[]' > ./output/keys.txt
  # RUN for pkg in $(make show-info | jq --raw-output --sort-keys 'keys[]' | head -n 70); \
  #       do \
  #         echo make $pkg-source; \
  #         make $pkg-source; \
  #       done;
  RUN make source;

  DO +SAVE_SELF --output=./output

  # SAVE ARTIFACT [--keep-ts] [--keep-own] [--if-exists] [--force] <src> [<artifact-dest-path>] [AS LOCAL <local-path>]

# test:
#   FROM --allow-privileged +docker

#   RUN --privileged ls -l /usr/lib/syslinux
#   # RUN --privileged make --quiet

build:
  FROM --allow-privileged +docker

  # RUN ../scripts/build.sh

# Add the basics startup scripts
  RUN cp -f ${OVERLAY}/etc/init.d/* package/initscripts/init.d/
  RUN install -C -m 0755 package/initscripts/init.d/* ${OVERLAY}/etc/init.d/

  RUN make oldconfig

  DO +COPY_SELF

  RUN make savedefconfig

  # RUN --privileged make --quiet
  RUN --privileged make

  # RUN ls -d ./output/*

  # FOR dir IN $(ls -d ./output/*)
  #   RUN echo ">>>> $dir"
  # END

  DO +SAVE_SELF --output=./output

all:
  BUILD +docker
  # BUILD +source
  BUILD +build




# KERNEL_VERSION  := 4.14.282
# BUSYBOX_VERSION := 1.35.0

# OUTPUTS := output/rootfs.tar.xz output/bzImage output/barge.iso output/barge.img

# BUILD_IMAGE     := barge-builder
# BUILD_CONTAINER := barge-built

# IS_BUILT := `docker ps -aq -f name=$(BUILD_CONTAINER) -f exited=0`
# IMAGE_ID := `docker inspect -f '{{.ID}}' $(BUILD_IMAGE) 2>/dev/null`

# DL_DIR     := /mnt/data/dl
# CCACHE_DIR := /mnt/data/ccache

# all: $(OUTPUTS)

# $(OUTPUTS): build | output
# 	docker cp $(BUILD_CONTAINER):/build/buildroot/output/images/$(@F) output/

# build:
# 	$(eval OLD_IMAGE_ID=$(shell docker inspect -f '{{.ID}}' $(BUILD_IMAGE) 2>/dev/null))
# 	docker build -t $(BUILD_IMAGE) .
# 	@if [ "$(OLD_IMAGE_ID)" != "$(IMAGE_ID)" ]; then \
# 		(docker rm -f $(BUILD_CONTAINER) || true); \
# 	fi
# 	@if [ "$(IS_BUILT)" = "" ]; then \
# 		set -e; \
# 		(docker rm -f $(BUILD_CONTAINER) || true); \
# 		docker run --privileged -v $(DL_DIR):/build/buildroot/dl \
# 			-v $(CCACHE_DIR):/build/buildroot/ccache --name $(BUILD_CONTAINER) $(BUILD_IMAGE); \
# 	fi

# output:
# 	@mkdir -p $@

# clean:
# 	-docker rm -f $(BUILD_CONTAINER)

# distclean: clean
# 	-docker rmi $(BUILD_IMAGE)
# 	$(RM) -r output

# .PHONY: all build clean distclean

# config: | output
# 	docker cp $(BUILD_CONTAINER):/build/buildroot/.config output/buildroot.config
# 	-diff configs/buildroot.config output/buildroot.config
# 	docker cp $(BUILD_CONTAINER):/build/buildroot/output/build/busybox-$(BUSYBOX_VERSION)/.config output/busybox.config
# 	-diff configs/busybox.config output/busybox.config
# 	docker cp $(BUILD_CONTAINER):/build/buildroot/output/build/linux-$(KERNEL_VERSION)/.config output/kernel.config
# 	-diff configs/kernel.config output/kernel.config

# .PHONY: config
