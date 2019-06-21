#!/bin/bash
function add_param_from_env() {
    local ENVVAR="$1"
    local PARAM="$2"
    local PARAMS="$3"
    if [ -z "$PARAM" ] ; then
        echo "usage: add_param_from_env [ENVVAR] [PARAM] [PARAMS]"
        return 1
    fi
    if [ ! -z "$ENVVAR" ] ; then
        if [ "$(echo "$PARAMS" | grep -- "$PARAM" || echo "false")" == "false" ] ; then
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
    PEMFILE=$(mktemp)
    PKCS12FILE=$(mktemp)
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
    LENGTH=$1
    if [ -z "$LENGTH" ] ; then
        LENGTH=10
    fi
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $LENGTH | head -n 1
}

function add_ssl_to_params() {
    local CA_CERT_LOCATION="$1"
    local USER_CERT_LOCATION="$2"
    local USER_KEY_LOCATION="$3"
    local CONFIG_ARG="$4"
    local PARAMS="$5"

    if [ ! -z "$CA_CERT_LOCATION" ] || [ ! -z "$USER_KEY_LOCATION" ] || [ ! -z "$USER_CERT_LOCATION" ] ; then
        if [ -z "$CA_CERT_LOCATION" ] ; then
            echo "Missing \$CA_CERT_LOCATION!"
            exit 1
        fi
        if [ -z "$USER_CERT_LOCATION" ] ; then
            echo "Missing \$USER_CERT_LOCATION!"
            exit 1
        fi
        if [ -z "$USER_KEY_LOCATION" ] ; then
            echo "Missing \$USER_KEY_LOCATION!"
            exit 1
        fi
        KEYSTORE_PASSWORD=$(rand_str 20)
        KEY_ALIAS="mykey"

        PARAMS=$(add_config_from_env "ssl" "$CONFIG_ARG" "security.protocol" "$PARAMS")

        # Keystore
        KEYSTORE_LOCATION=/tmp/kafka-keystore-$(rand_str 5).jks
        pem_to_keystore "$KEYSTORE_LOCATION" "$USER_CERT_LOCATION" "$KEYSTORE_PASSWORD" "$KEY_ALIAS" "$USER_KEY_LOCATION" 2&>1 > /dev/null
        PARAMS=$(add_config_from_env "$KEYSTORE_LOCATION" "$CONFIG_ARG" "ssl.keystore.location" "$PARAMS")
        PARAMS=$(add_config_from_env "$KEYSTORE_PASSWORD" "$CONFIG_ARG" "ssl.keystore.password" "$PARAMS")

        # Truststore
        TRUSTSTORE_LOCATION=/tmp/kafka-truststore-$(rand_str 5).jks
        pem_to_truststore "$TRUSTSTORE_LOCATION" "$CA_CERT_LOCATION" "$KEYSTORE_PASSWORD" "$KEY_ALIAS" 2&>1 > /dev/null
        PARAMS=$(add_config_from_env "$TRUSTSTORE_LOCATION" "$CONFIG_ARG" "ssl.truststore.location" "$PARAMS")
        PARAMS=$(add_config_from_env "$KEYSTORE_PASSWORD" "$CONFIG_ARG" "ssl.truststore.password" "$PARAMS")
    fi
    echo "$PARAMS"
}
