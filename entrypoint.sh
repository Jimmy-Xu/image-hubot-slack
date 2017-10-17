#!/bin/bash

if [ "${HYPER_ACCESS_KEY}" != "" -a "${HYPER_SECRET_KEY}" != "" ];then
    REGION=${REGION:-us-west-1}
    API_ROUTER=${API_ROUTER:-tcp://us-west-1.hyper.sh:443}

    #ensure config for hyper cli
    HYPER_CONFIG=~/.hyper
    mkdir -p ${HYPER_CONFIG}
    cat > ${HYPER_CONFIG}/config.json <<EOF
{
    "clouds": {
        "${API_ROUTER}": {
            "accesskey": "${HYPER_ACCESS_KEY}",
            "secretkey": "${HYPER_SECRET_KEY}",
            "region": "${REGION}"
        },
        "tcp://*.hyper.sh:443": {
            "accesskey": "${HYPER_ACCESS_KEY}",
            "secretkey": "${HYPER_SECRET_KEY}",
            "region": "${REGION}"
        }
    }
}
EOF
fi

if [ "PROXY_SERVER" != "" ];then
    echo "${PROXY_PROTOCOL:-http} 	${PROXY_SERVER} ${PROXY_PORT:-1080}" >> ${PROXY_CONFIG}
fi

exec "$@"
