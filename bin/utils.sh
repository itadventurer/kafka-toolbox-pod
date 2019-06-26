#!/bin/bash
function add_param_from_env() {
    local ENVVAR="$1"
    local PARAM="$2"
    local PARAMS="$3"
    if [ ! -z "$ENVVAR" ] ; then
        if [ -z "$PARAM" ] || [ "$(echo "$PARAMS" | grep -- "$PARAM" || echo "false")" == "false" ] ; then
            PARAMS="$PARAM $ENVVAR $PARAMS"
        fi
    fi
    echo "$PARAMS"
}

function add_config_from_env() {
    local ENVVAR="$1"
    local ARGNAME="$2"
    local PARAM="$3"
    local PARAMS="$4"
    if [ -z "$PARAM" ] ; then
        echo "usage: add_config_from_env [ENVVAR] [ARGNAME] [PARAM] [PARAMS]"
        return 1
    fi
    if [ ! -z "$ENVVAR" ] ; then
        PARAMS="$ARGNAME $PARAM=$ENVVAR $PARAMS"
    fi
    echo "$PARAMS"
}

function pem_to_truststore() {
    local KEYSTORE_LOCATION="$1"
    local CERT_LOCATION="$2"
    local KEYSTORE_PASSWORD="$3"
    local KEY_ALIAS="$4"
    if [ -z "$KEY_ALIAS" ] ; then
        echo "usage: pem_to_truststore [KEYSTORE_LOCATION] [CERT_LOCATION] [KEYSTORE_PASSWORD] [KEY_ALIAS]"
        return 1
    fi
    keytool -import -noprompt \
            -keystore "$KEYSTORE_LOCATION" \
             -file "$CERT_LOCATION" \
            -storepass "$KEYSTORE_PASSWORD" \
            -alias "$KEY_ALIAS"
}

function pem_to_keystore() {
    local KEYSTORE_LOCATION="$1"
    local CERT_LOCATION="$2"
    local KEYSTORE_PASSWORD="$3"
    local KEY_ALIAS="$4"
    local KEY_LOCATION="$5"
    if [ -z "$KEY_LOCATION" ] ; then
        echo "usage: pem_to_keystore [KEYSTORE_LOCATION] [CERT_LOCATION] [KEYSTORE_PASSWORD] [KEY_ALIAS] [KEY_LOCATION]"
        return 1
    fi

    # If a key and a cert is given, create a keystore
    local PEMFILE=$(mktemp)
    local PKCS12FILE=$(mktemp)
    cat "$KEY_LOCATION" "$CERT_LOCATION" > $PEMFILE

    # Create pkcs12 file
    openssl pkcs12 -export \
            -out $PKCS12FILE \
            -in $PEMFILE \
            -passout pass:"$KEYSTORE_PASSWORD"

    # Create Java Keystore
    keytool -v -importkeystore \
            -srckeystore $PKCS12FILE \
            -srcstoretype PKCS12 \
            -destkeystore "$KEYSTORE_LOCATION" \
            -storepass "$KEYSTORE_PASSWORD" \
            -srcstorepass "$KEYSTORE_PASSWORD" \
            -alias 1 \
            -destalias "$KEY_ALIAS"

    rm $PEMFILE $PKCS12FILE
}

function rand_str() {
    local LENGTH=$1
    if [ -z "$LENGTH" ] ; then
        LENGTH=10
    fi
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $LENGTH | head -n 1
}

function add_tls() {
    local PARAMS="$1"
    local PARAM="$2"

    if [ ! -z "$KAFKA_CA_CERT_LOCATION" ] || [ ! -z "$KAFKA_USER_KEY_LOCATION" ] || [ ! -z "$KAFKA_USER_CERT_LOCATION" ] ; then
        if [ -z "$KAFKA_CA_CERT_LOCATION" ] ; then
            echo "Missing \$KAFKA_CA_CERT_LOCATION!"
            exit 1
        fi
        if [ -z "$KAFKA_USER_CERT_LOCATION" ] ; then
            echo "Missing \$KAFKA_USER_CERT_LOCATION!"
            exit 1
        fi
        if [ -z "$KAFKA_USER_KEY_LOCATION" ] ; then
            echo "Missing \$KAFKA_USER_KEY_LOCATION!"
            exit 1
        fi
        local KEYSTORE_PASSWORD=$(rand_str 20)
        local KEY_ALIAS="mykey"
        local CONFIG_FILE=$(mktemp)

        echo "security.protocol: ssl" >> $CONFIG_FILE

        # Keystore
        local KEYSTORE_LOCATION=/tmp/kafka-keystore-$(rand_str 5).jks
        pem_to_keystore "$KEYSTORE_LOCATION" "$KAFKA_USER_CERT_LOCATION" "$KEYSTORE_PASSWORD" "$KEY_ALIAS" "$KAFKA_USER_KEY_LOCATION"
        echo "ssl.keystore.location: $KEYSTORE_LOCATION" >> $CONFIG_FILE
        echo "ssl.keystore.password: $KEYSTORE_PASSWORD" >> $CONFIG_FILE

        # Truststore
        local TRUSTSTORE_LOCATION=/tmp/kafka-truststore-$(rand_str 5).jks
        pem_to_truststore "$TRUSTSTORE_LOCATION" "$KAFKA_CA_CERT_LOCATION" "$KEYSTORE_PASSWORD" "$KEY_ALIAS"
        echo "ssl.truststore.location: $TRUSTSTORE_LOCATION" >> $CONFIG_FILE
        echo "ssl.truststore.password: $KEYSTORE_PASSWORD" >> $CONFIG_FILE

        PARAMS=$(add_param_from_env $CONFIG_FILE "$PARAM" "$PARAMS")
    fi
    echo "$PARAMS"
}

function add_zookeeper() {
    local PARAMS="$1"
    local PARAM="$2"
    local PARAMS=$(add_param_from_env "$KAFKA_ZOOKEEPER" "$PARAM" "$PARAMS")
    echo "$PARAMS"
}

function add_bootstrap_servers() {
    local PARAMS="$1"
    local PARAM="$2"
    local PARAMS=$(add_param_from_env "$KAFKA_BOOTSTRAP_SERVERS" "$PARAM" "$PARAMS")
    echo "$PARAMS"
}
