#!/bin/bash
if [ -z "$PARAMS" ] ; then
    PARAMS="$@"
fi
DIR=$( dirname "${BASH_SOURCE[0]}" )
source "$DIR/utils.sh"

if [ ! -z "$ZOOKEEPER_PARAM" ] ; then
    PARAMS=$(add_zookeeper "$PARAMS" "$ZOOKEEPER_PARAM")
fi

if [ ! -z "$BOOTSTRAP_SERVERS_PARAM" ] ; then
    PARAMS=$(add_bootstrap_servers "$PARAMS" "$BOOTSTRAP_SERVERS_PARAM")
fi

if [ ! -z "$TLS_CONFIG_PARAM" ] ; then
PARAMS=$(add_tls "$PARAMS" "$TLS_CONFIG_PARAM")
fi

if [ ! -z "$DEBUG" ] ; then
    echo "$KAFKA_CLI_DIR/$(basename $0).sh $PARAMS"
fi

exec $KAFKA_CLI_DIR/$(basename $0).sh $PARAMS
