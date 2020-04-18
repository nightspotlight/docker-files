#!/usr/bin/env bash

# requires: docker-compose

shopt -s extglob globstar nullglob

SELF_DIR=$(dirname "${BASH_SOURCE[0]}")
OPTIONS=()

for FILE in "${SELF_DIR}"/common/docker-compose.yml "${SELF_DIR}"/!(common)/docker-compose.yml
do
  test -f "${FILE}" && OPTIONS+=("-f" "${FILE}")
done

docker-compose "${OPTIONS[@]}" "${@}"
