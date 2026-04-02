#!/bin/bash

set -euo pipefail
set -x

STAGING_DIR="/tmp/ext-jars"
if [ -d "$STAGING_DIR" ] && ls "$STAGING_DIR"/*.jar 1> /dev/null 2>&1; then
  echo "--> Copying custom jars from volume to Hive..."
  cp -vf "$STAGING_DIR"/*.jar "${HIVE_HOME}/lib/"
fi

: "${HIVE_WAREHOUSE_PATH:=/opt/hive/data/warehouse}"
export HIVE_WAREHOUSE_PATH

envsubst < "$HIVE_HOME/conf/core-site.xml.template" > "$HIVE_HOME/conf/core-site.xml"

if [ -f "${HIVE_CUSTOM_HIVE_SITE:-}" ]; then
  cp "${HIVE_CUSTOM_HIVE_SITE}" "$HIVE_HOME/conf/hive-site.xml"
else
  envsubst < "$HIVE_HOME/conf/hive-site.xml.template" > "$HIVE_HOME/conf/hive-site.xml"
fi

: "${DB_DRIVER:=derby}"
SKIP_SCHEMA_INIT="${IS_RESUME:-false}"
[[ "${VERBOSE:-}" = "true" ]] && VERBOSE_MODE="--verbose"

initialize_hive() {
  COMMAND="-initOrUpgradeSchema"
  if [ "$(echo "$HIVE_VER" | cut -d '.' -f1)" -lt "4" ]; then
    COMMAND="-${SCHEMA_COMMAND:-initSchema}"
  fi

  if [[ -n "${VERBOSE_MODE:-}" ]]; then
    "$HIVE_HOME/bin/schematool" -dbType "$DB_DRIVER" "$COMMAND" "$VERBOSE_MODE"
  else
    "$HIVE_HOME/bin/schematool" -dbType "$DB_DRIVER" "$COMMAND"
  fi

  if [ $? -eq 0 ]; then
    echo "Initialized Hive Metastore Server schema successfully.."
  else
    echo "Hive Metastore Server schema initialization failed!"
    exit 1
  fi
}

export HIVE_CONF_DIR="$HIVE_HOME/conf"
export HADOOP_CONF_DIR="$HIVE_CONF_DIR"
export TEZ_CONF_DIR="$HIVE_CONF_DIR"
export HADOOP_CLIENT_OPTS="${HADOOP_CLIENT_OPTS:-} -Xmx1G $SERVICE_OPTS"

if [[ "${SKIP_SCHEMA_INIT}" == "false" ]]; then
  initialize_hive
fi

if [ "${SERVICE_NAME}" == "hiveserver2" ]; then
  export HADOOP_CLASSPATH="$TEZ_HOME/*:$TEZ_HOME/lib/*:$HADOOP_CLASSPATH"
  exec "$HIVE_HOME/bin/hive" --skiphadoopversion --skiphbasecp --service "$SERVICE_NAME"
elif [ "${SERVICE_NAME}" == "metastore" ]; then
  export METASTORE_PORT="${METASTORE_PORT:-9083}"
  if [[ -n "${VERBOSE_MODE:-}" ]]; then
    exec "$HIVE_HOME/bin/hive" --skiphadoopversion --skiphbasecp "$VERBOSE_MODE" --service "$SERVICE_NAME"
  else
    exec "$HIVE_HOME/bin/hive" --skiphadoopversion --skiphbasecp --service "$SERVICE_NAME"
  fi
fi
