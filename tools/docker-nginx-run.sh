#!/usr/bin/env bash

# requires: docker

# Variables
NGINX_NETWORK_NAME="nginx-proxy"
NGINX_PROXY_NAME="nginx-proxy"
NGINX_PROXY_IMAGE="jwilder/nginx-proxy:alpine"
NGINX_LETSENCRYPT_NAME="nginx-letsencrypt"
NGINX_LETSENCRYPT_IMAGE="jrcs/letsencrypt-nginx-proxy-companion:latest"
NGINX_DATA_PATH="/srv/docker/nginx"

# Prepare mounts
mkdir -p \
  "${NGINX_DATA_PATH}" \
  "${NGINX_DATA_PATH}/ssl/certificates" \
  "${NGINX_DATA_PATH}/vhost.d"
touch "${NGINX_DATA_PATH}/proxy.conf"

echo "Updating images..."
if docker pull "${NGINX_PROXY_IMAGE}"
then IMAGE_LATEST[0]="$(docker image inspect --format "{{.Id}}" "${NGINX_PROXY_IMAGE}")"
fi

if docker pull "${NGINX_LETSENCRYPT_IMAGE}"
then IMAGE_LATEST[1]="$(docker image inspect --format "{{.Id}}" "${NGINX_LETSENCRYPT_IMAGE}")"
fi

echo -n "Creating a virtual network... "
docker network create "${NGINX_NETWORK_NAME}" 2>/dev/null \
  || echo "virtual network ${NGINX_NETWORK_NAME} already exists"

echo "Checking running containers' images"
if docker ps -f "name=${NGINX_PROXY_NAME}" --format "{{.Names}}" | grep -q "${NGINX_PROXY_NAME}"
then IMAGE_RUNNING[0]="$(docker container inspect --format "{{.Image}}" "${NGINX_PROXY_NAME}")"
fi

if docker ps -f "name=${NGINX_LETSENCRYPT_NAME}" --format "{{.Names}}" | grep -q "${NGINX_LETSENCRYPT_NAME}"
then IMAGE_RUNNING[1]="$(docker container inspect --format "{{.Image}}" "${NGINX_LETSENCRYPT_NAME}")"
fi

# Compare downloaded image's and running image's digests
# If they don't match, recreate the containers
if [ "${IMAGE_RUNNING[0]}" != "${IMAGE_LATEST[0]}" ] # nginx-proxy
then
  docker stop "${NGINX_PROXY_NAME}" 2>/dev/null || true
  docker rm "${NGINX_PROXY_NAME}" 2>/dev/null || true
  echo -n "Creating container ${NGINX_PROXY_NAME}... "
  docker run \
    --detach \
    --interactive \
    --tty \
    --label com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy=true \
    --publish 80:80 \
    --publish 443:443 \
    --restart unless-stopped \
    --volume "${NGINX_DATA_PATH}/ssl/certificates:/etc/nginx/certs:ro" \
    --volume "${NGINX_DATA_PATH}/vhost.d:/etc/nginx/vhost.d" \
    --volume "${NGINX_DATA_PATH}/proxy.conf:/etc/nginx/conf.d/proxy.conf:ro" \
    --volume nginx-html:/usr/share/nginx/html \
    --volume /var/run/docker.sock:/tmp/docker.sock:ro \
    --network "${NGINX_NETWORK_NAME}" \
    --name "${NGINX_PROXY_NAME}" \
    "${NGINX_PROXY_IMAGE}" || { echo "Error creating ${NGINX_PROXY_NAME}!"; exit 1; }
else
  echo "Container ${NGINX_PROXY_NAME} is up to date"
fi

if [ "${IMAGE_RUNNING[1]}" != "${IMAGE_LATEST[1]}" ] # nginx-letsencrypt
then
  docker stop "${NGINX_LETSENCRYPT_NAME}" 2>/dev/null || true
  docker rm "${NGINX_LETSENCRYPT_NAME}" 2>/dev/null || true
  echo -n "Creating container ${NGINX_LETSENCRYPT_NAME}... "
  docker run \
    --detach \
    --interactive \
    --tty \
    --restart unless-stopped \
    --volume "${NGINX_DATA_PATH}/ssl/certificates:/etc/nginx/certs" \
    --volume "${NGINX_DATA_PATH}/vhost.d:/etc/nginx/vhost.d" \
    --volume nginx-html:/usr/share/nginx/html \
    --volume /var/run/docker.sock:/var/run/docker.sock:ro \
    --network "${NGINX_NETWORK_NAME}" \
    --name "${NGINX_LETSENCRYPT_NAME}" \
    "${NGINX_LETSENCRYPT_IMAGE}" || { echo "Error creating ${NGINX_LETSENCRYPT_NAME}!"; exit 1; }
else
  echo "Container ${NGINX_LETSENCRYPT_NAME} is up to date"
fi
