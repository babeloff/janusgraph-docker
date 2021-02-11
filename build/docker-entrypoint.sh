#!/bin/bash
#
# Copyright 2019 JanusGraph Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

JANUS_PROPS="${JANUS_CONFIG_DIR}/janusgraph.properties"
GREMLIN_YAML="${JANUS_CONFIG_DIR}/gremlin-server.yaml"

# running as root; step down to run as janusgraph user
if [ "$1" == 'janusgraph' ] && [ "$(id -u)" == "0" ]; then
  mkdir -p "${JANUS_DATA_DIR}" "${JANUS_CONFIG_DIR}"
  chown -R janusgraph:janusgraph "${JANUS_DATA_DIR}" "${JANUS_CONFIG_DIR}"
  chmod 700 "${JANUS_DATA_DIR}" "${JANUS_CONFIG_DIR}"

  exec chroot --skip-chdir --userspec janusgraph:janusgraph / "${BASH_SOURCE}" "$@"
fi

# running as non root user
if [ "$1" == 'janusgraph' ]; then
  # setup config directory
  mkdir -p "${JANUS_DATA_DIR}" "${JANUS_CONFIG_DIR}"
  cp "conf/gremlin-server/janusgraph-${JANUS_PROPS_TEMPLATE}-server.properties" "${JANUS_CONFIG_DIR}/janusgraph.properties"
  cp conf/gremlin-server/gremlin-server.yaml "${JANUS_CONFIG_DIR}"
  chown -R "$(id -u):$(id -g)" "${JANUS_DATA_DIR}" "${JANUS_CONFIG_DIR}"
  chmod 700 "${JANUS_DATA_DIR}" "${JANUS_CONFIG_DIR}"
  chmod -R 600 "${JANUS_CONFIG_DIR}"/*

  # apply configuration from environment
  while IFS='=' read -r env_var_key env_var_val; do
    if [[ "${env_var_key}" =~ janusgraph\. ]] && [[ -n ${env_var_val} ]]; then
      # strip namespace and use properties file delimiter for janusgraph properties
      env_var_key=${env_var_key#"janusgraph."}
      # Add new or update existing field in configuration file
      if grep -q -E "^\s*${env_var_key}\s*=\.*" "${JANUS_PROPS}"; then
        sed -ri "s#^(\s*${env_var_key}\s*=).*#\\1${env_var_val}#" "${JANUS_PROPS}"
      else
        echo "${env_var_key}=${env_var_val}" >> "${JANUS_PROPS}"
      fi
    elif [[ "${env_var_key}" =~ gremlinserver_[[:alnum:]_.-]{1,30} ]]; then
      yq eval --prettyPrint --inplace "${GREMLIN_YAML}" "${env_var_val}"
    else
      continue
    fi
  done < <(env)

  if [ "$2" == 'show-config' ]; then
    echo "# contents of ${JANUS_PROPS}"
    cat "$JANUS_PROPS"
    echo "---------------------------------------"
    echo "# contents of ${GREMLIN_YAML}"
    cat "$GREMLIN_YAML"
    exit 0
  else
    # wait for storage
    if [ -n "${JANUS_STORAGE_TIMEOUT:-}" ]; then
      F="$(mktemp --suffix .groovy)"
      echo "graph = JanusGraphFactory.open('${JANUS_CONFIG_DIR}/janusgraph.properties')" > "$F"
      timeout "${JANUS_STORAGE_TIMEOUT}s" bash -c \
        "until bin/gremlin.sh -e $F > /dev/null 2>&1; do echo \"waiting for storage...\"; sleep 5; done"
      rm -f "$F"
    fi

    /usr/local/bin/load-initdb.sh &

    exec "${JANUS_HOME}/bin/gremlin-server.sh" "${JANUS_CONFIG_DIR}/gremlin-server.yaml"
  fi
fi

# override hosts for remote connections with Gremlin Console
if [ -n "${GREMLIN_REMOTE_HOSTS:-}" ]; then
  sed -i "s/hosts\s*:.*/hosts: [$GREMLIN_REMOTE_HOSTS]/" "${JANUS_HOME}/conf/remote.yaml"
fi

exec "$@"
