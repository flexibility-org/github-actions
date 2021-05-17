#!/usr/bin/env bash

set -euxo pipefail

# The following line comes from: https://stackoverflow.com/a/246128
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

check_set() {
  # The following use of array substitution is due to
  # https://stackoverflow.com/a/8435349
  subst="$1[@]"
  if [[ -z "${!subst}" ]]; then
    printf "Required environment variable (${1}) is not set\n" >&2
    exit 1
  fi
}

check_set ELASTIC_VERSION
check_set ELASTIC_PORT
check_set KIBANA_VERSION
check_set KIBANA_PORT

docker run \
  --rm \
  --volume "${script_dir}/config/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml" \
  --volume "${script_dir}/config/elastic-certificates.p12:/usr/share/elasticsearch/config/elastic-certificates.p12" \
  --env "http.port=${ELASTIC_PORT}" \
  --env "ELASTIC_PASSWORD=changeme" \
  --env "ES_JAVA_OPTS=-Xms1g -Xmx1g" \
  --ulimit nofile=65536:65536 \
  --ulimit memlock=-1:-1 \
  --publish "${ELASTIC_PORT}:${ELASTIC_PORT}" \
  --network host \
  --detach \
  "elasticsearch:${ELASTIC_VERSION}"

docker run \
  --rm \
  --volume "${script_dir}/config/kibana.yml:/usr/share/kibana/config/kibana.yml" \
  --env "server.port=${KIBANA_PORT}" \
  --env "ELASTICSEARCH_HOSTS=http://localhost:9200" \
  --publish "${KIBANA_PORT}:${KIBANA_PORT}" \
  --network host \
  --detach \
  "kibana:${KIBANA_VERSION}"

exec "${script_dir}/wait_for_url.sh" --body '' "http://localhost:${KIBANA_PORT}"
