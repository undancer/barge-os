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

docker-base:
  FROM DOCKERFILE \
    .  

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
