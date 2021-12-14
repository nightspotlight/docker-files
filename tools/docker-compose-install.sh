#!/usr/bin/env bash

# requires: curl
# requires: jq

current_user="$(id -u)"
platform="$(uname -s)-$(uname -m)"
api_url="https://api.github.com/repos/docker/compose/releases/latest"
query_latest_version=".tag_name"
query_download_url=".assets[] | .browser_download_url | select(endswith(\"${platform,,}\"))"
version="$(curl -s "${api_url}" | jq -cr "${query_latest_version}")"
source="$(curl -s "${api_url}" | jq -cr "${query_download_url}")"
source_completion="https://raw.githubusercontent.com/docker/compose/${version}/contrib/completion/bash/docker-compose"
if test "${current_user}" -eq 0; then
  target="/usr/local/bin/docker-compose"
  target_completion="/etc/bash_completion.d/docker-compose"
else
  target="${HOME}/bin/docker-compose"
  target_completion="${HOME}/.bash_completion.d/docker-compose"
fi
mkdir -p "${target%/*}" "${target_completion%/*}"

test "${source}" || { echo "Download location not found"; exit 1; }

echo "Installed version: $("${target}" --version 2>/dev/null || echo "None")"
echo "Downloading version: ${version}"

curl -s -L "${source}" -o "${target}" && chmod +x "${target}"

if ! curl -s -L "${source_completion}" -o "${target_completion}"; then
  { echo "Cannot save bash completion file"; exit 1; }
fi

echo "Done"
