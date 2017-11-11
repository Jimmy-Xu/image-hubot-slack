#!/usr/bin/env bash

function show_usage() {
    cat <<EOF
usage: ./start.sh <OPTION>

OPTION:
    init          # install external scripts
    proxychains   # start with proxychains
    imap_proxy    # start with imap proxy(ptunnel as http proxy)
    no_proxy      # start without proxy
    slack         # use slack as adapter
EOF
    exit
}

function generate_config() {
    sed -i "s|{COOKIE}|$WX_COOKIE|g" config.yaml
    sed -i "s/{UIN}/$WX_UIN/g" config.yaml
    sed -i "s/{SID}/$WX_SID/g" config.yaml
    sed -i "s/{SKEY}/$WX_SKEY/g" config.yaml
    sed -i "s/{DEVICEID}/$WX_DEVICEID/g" config.yaml

    cp node_modules/hubot-another-weixin/example/weixin-notify-growl.coffee scripts/
}

function show_env() {
    echo "--------------------------------"
    netstat -tnopl
    echo "--------------------------------"

cat <<EOF
#################################
USE_EXT_HTTP_PROXY: ${USE_EXT_HTTP_PROXY}
  HTTP_PROXY_IP:      ${HTTP_PROXY_IP}
  HTTP_PROXY_PORT:    ${HTTP_PROXY_PORT}
USE_EXT_SSLOCAL:    ${USE_EXT_SSLOCAL}
  SOCKS5_PROXY_IP:    ${SOCKS5_PROXY_IP}
  SOCKS5_PROXY_PORT:  ${SOCKS5_PROXY_PORT}
USE_EXT_SSSERVER:   ${USE_EXT_SSSERVER}
  SS_SERVER:          ${SS_SERVER}
  SS_PORT:            ${SS_PORT}
  SS_PASSWORD:        ${SS_PASSWORD}
  SS_METHOD:          ${SS_METHOD}

hubot-gmail-growl:
  HUBOT_GMAIL_USERNAME:       ${HUBOT_GMAIL_USERNAME}
  HUBOT_GMAIL_PASSWORD:       ***********${HUBOT_GMAIL_PASSWORD:7}
  HUBOT_GMAIL_LABEL:          ${HUBOT_GMAIL_LABEL}
  HUBOT_GMAIL_CHECK_INTERVAL: ${HUBOT_GMAIL_CHECK_INTERVAL}
  HUBOT_IMAP_PROXY_SERVER:    ${HUBOT_IMAP_PROXY_SERVER}
  HUBOT_IMAP_PROXY_PORT:      ${HUBOT_IMAP_PROXY_PORT}

hubot-another-weixin:
  HUBOT_WATCH_GROUPS:    ${HUBOT_WATCH_GROUPS}
  HUBOT_WATCH_GH:        ${HUBOT_WATCH_GH}
  HUBOT_WATCH_USERS:     ${HUBOT_WATCH_USERS}
  WX_COOKIE:             ${WX_COOKIE}
  WX_UIN:                ${WX_UIN}
  WX_SID:                ${WX_SID}
  WX_SKEY:               ${WX_SKEY}
  WX_DEVICEID:           ${WX_DEVICEID}
#################################
EOF
}

case $1 in
    init)
        echo "install external scripts"
        node -e "console.log(JSON.stringify('$EXTERNAL_SCRIPTS'.split(',')))" > external-scripts.json && npm install $(node -e "console.log('$EXTERNAL_SCRIPTS'.split(',').join(' '))")
        ;;
    proxychains)
        echo "start with proxychains"
        unset HUBOT_IMAP_PROXY_SERVER
        unset HUBOT_IMAP_PROXY_PORT
        show_env
        HUBOT_LOG_LEVEL=debug proxychains4 -q bin/hubot -n $HUBOT_NAME
        ;;
    imap_proxy)
        echo "start without proxy"
        show_env
        export HUBOT_IMAP_PROXY_SERVER=${HUBOT_IMAP_PROXY_SERVER:-127.0.0.1}
        export HUBOT_IMAP_PROXY_PORT=${HUBOT_IMAP_PROXY_PORT:=5993}
        HUBOT_LOG_LEVEL=debug bin/hubot -n $HUBOT_NAME
        ;;
    no_proxy)
        unset HUBOT_IMAP_PROXY_SERVER
        unset HUBOT_IMAP_PROXY_PORT
        show_env
        HUBOT_LOG_LEVEL=debug bin/hubot -n $HUBOT_NAME
        ;;
    slack)
        show_env
        HUBOT_LOG_LEVEL=debug bin/hubot -n $HUBOT_NAME --adapter slack
        ;;
    weixin)
        generate_config
        show_env
        bin/hubot -n $HUBOT_NAME --adapter another-weixin
        ;;
    *)
        show_usage
        ;;
esac
