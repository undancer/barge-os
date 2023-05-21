#!/usr/bin/env bash
set -x -v

docker run \
  --privileged \
  --rm \
  -t \
  --env EARTHLY_BUILD_ARGS \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$(pwd)":/workspace \
  -v earthly-tmp:/tmp/earthly:rw \
  earthly/earthly:v0.7.5 --allow-privileged "$@"
