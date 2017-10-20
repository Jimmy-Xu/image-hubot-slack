#!/bin/bash

function start_privoxy() {
    echo ">Start privoxy"
    if [ $UID -eq 0 ];then
        service privoxy start
        IS_RUNNING=$(service privoxy status | grep "privoxy is running" 2>/dev/null | wc -l)
    else
        screen -S privoxy -d -m bash -c "/usr/sbin/privoxy --no-daemon $PRIVOXY_CONF"
        IS_RUNNING=$(screen -ls | grep privoxy 2>/dev/null | wc -l)
    fi
    if [ ${IS_RUNNING} -ne 1 ];then
        echo "start http proxy(privoxy) failed"
        exit 2
    fi
    echo "http proxy(privoxy) is running"
    export HTTP_PROXY_IP="127.0.0.1"
    export HTTP_PROXY_PORT="8118"
}

function start_sslocal() {
    echo ">Start sslocal"
    if [ $UID -eq 0 ];then
        service sslocal start
        IS_RUNNING=$(service sslocal status | grep "sslocal is running" 2>/dev/null | wc -l)
    else
        screen -S sslocal -d -m bash -c "/usr/bin/python /usr/local/bin/sslocal -c ${SSLOCAL_CONF}"
        IS_RUNNING=$(screen -ls | grep sslocal 2>/dev/null | wc -l)
    fi
    if [ ${IS_RUNNING} -ne 1 ];then
        echo "start socks5 proxy(sslcoal) failed"
        exit 3
    fi
    echo "socks5 proxy(sslocal) is running"
    export SOCKS5_PROXY_IP="127.0.0.1"
    export SOCKS5_PROXY_PORT="1080"
}

function start_ptunnel() {
    echo "-----------------------------------------------------------------------"
    echo "Enable ${PROXY_SOLUTION}"
    echo "-----------------------------------------------------------------------"
    screen -S ptunnel -d -m bash -c "/usr/bin/python ptunnel.py -d -p ${HTTP_PROXY_IP}:${HTTP_PROXY_PORT} ${HUBOT_IMAP_PROXY_PORT}:imap.gmail.com:993"
    RLT=$(screen -ls | grep ptunnel | wc -l)
    if [ ${RLT} -ne 1 ];then
        echo "Start ptunnel failed"
        exit 4
    else
        echo "Start ptunnel OK"
    fi
}

# check switch for proxy
if [ "${USE_EXT_HTTP_PROXY}" != "0" -a "${USE_EXT_SSLOCAL}" != "0" -a "${USE_EXT_SSSERVER}" != "0" ];then
  echo "You can only use one of these: USE_EXT_HTTP_PROXY, USE_EXT_SSLOCAL, USE_EXT_SSSERVER"
  exit 1
fi

# check env for hypercli
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


PROXY_SOLUTION="no proxy"

#============================================
# solution1:
#   internal: ptunnel.py
#   external: http_proxy(privoxy)
#============================================
## external http proxy(Example: 192.168.1.137:8118)
if [ "${USE_EXT_HTTP_PROXY}" != "0" ];then
    if [ "${HTTP_PROXY_IP}" == "" -o "${HTTP_PROXY_PORT}" == "" ];then
        echo "You have to specified HTTP_PROXY_IP and HTTP_PROXY_PORT when USE_EXT_HTTP_PROXY is specified"
        exit 10
    fi
    export PROXY_SOLUTION="solution1"
    ## update proxychains
    echo ">Update ${PROXYCHAINS_CONF} (external http proxy)"
    echo "http  ${HTTP_PROXY_IP} ${HTTP_PROXY_PORT}" >> ${PROXYCHAINS_CONF}
    echo "-----------------------------------------"
    grep '\[ProxyList\]' -A4 ${PROXYCHAINS_CONF} | grep -v "#"
    echo "-----------------------------------------"
fi


#====================================================================
# solution2:
#   internal: ptunnel.py, http_proxy(privoxy)
#   external: socks5_proxy(sslocal)
#====================================================================
## external sslocal (Example: 192.168.1.137:1080)
if [ "${USE_EXT_SSLOCAL}" != "0" ];then
    if [ "$SOCKS5_PROXY_IP" == "" -o "$SOCKS5_PROXY_PORT" == "" ];then
        echo "You have to specified SOCKS5_PROXY_IP and SOCKS5_PROXY_PORT when USE_EXT_SSLOCAL is specified"
        exit 20
    fi
    export PROXY_SOLUTION="solution2"

    ## start privoxy
    echo ">Update $PRIVOXY_CONF"
    sed -i "/forward-socks5.*:1080/c\forward-socks5 / ${SOCKS5_PROXY_IP}:${SOCKS5_PROXY_PORT} ." $PRIVOXY_CONF
    echo "-----------------------------------------"
    cat $PRIVOXY_CONF
    start_privoxy

    ## update proxychains
    echo ">Update ${PROXYCHAINS_CONF} (internal http proxy + external socks5 proxy)"
    #echo "http  ${HTTP_PROXY_IP} ${HTTP_PROXY_PORT}" >> ${PROXYCHAINS_CONF}
    echo "socks5  ${SOCKS5_PROXY_IP} ${SOCKS5_PROXY_PORT}" >> ${PROXYCHAINS_CONF}
    echo "-----------------------------------------"
    grep '\[ProxyList\]' -A4 ${PROXYCHAINS_CONF} | grep -v "#"
    echo "-----------------------------------------"
fi


#====================================================================
# solution3:
#   internal: ptunnel.py, http_proxy(privoxy), socks5_proxy(sslocal)
#   external: shadowsocks(ssserver)
#====================================================================
## external shadowsocks server
if [ "${USE_EXT_SSSERVER}" != "0" ];then
    if [ "SS_SERVER" == "" -o "SS_PASSWORD" == "" ];then
        echo "You have to specified SS_SERVER and SS_PASSWORD when USE_EXT_SSSERVER is specified"
        exit 30
    fi
    export PROXY_SOLUTION="solution3"

    ## start sslocal
    echo ">Update $SSLOCAL_CONF"
    cat > $SSLOCAL_CONF <<EOF
{
  "server": "${SS_SERVER}",
  "server_port": ${SS_PORT:-8338},
  "password": "${SS_PASSWORD}",
  "method": "${SS_METHOD:-aes-256-cfb}",
  "local_address": "0.0.0.0",
  "local_port": 1080,
  "timeout": 600
}
EOF
    ## start sslocal
    start_sslocal

    ## start privoxy
    start_privoxy

    ## update proxychains
    echo ">Update ${PROXYCHAINS_CONF} (internal http proxy + internal socks5 proxy)"
    #echo "http  ${HTTP_PROXY_IP} ${HTTP_PROXY_PORT}" >> ${PROXYCHAINS_CONF}
    echo "socks5  ${SOCKS5_PROXY_IP} ${SOCKS5_PROXY_PORT}" >> ${PROXYCHAINS_CONF}
    echo "-----------------------------------------"
    grep '\[ProxyList\]' -A4 ${PROXYCHAINS_CONF} | grep -v "#"
    echo "-----------------------------------------"
fi

if [ "${PROXY_SOLUTION}" != "no proxy" ];then
    start_ptunnel
    export HUBOT_IMAP_PROXY_SERVER=${HUBOT_IMAP_PROXY_SERVER:-127.0.0.1}
    export HUBOT_IMAP_PROXY_PORT=${HUBOT_IMAP_PROXY_PORT:=5993}
fi

cat <<EOF
#################################
USER:            $(whoami)
PROXY_SOLUTION:  ${PROXY_SOLUTION}

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

hypercli:
  HYPER_ACCESS_KEY:     *****${HYPER_ACCESS_KEY:10}
  HYPER_SECRET_KEY:     *****${HYPER_SECRET_KEY:10}
  API_ROUTER:           ${API_ROUTER}
  REGION:               ${REGION}

slack:
  HUBOT_SLACK_TOKEN:  **********${HUBOT_SLACK_TOKEN:20}

gntp-send:
  HUBOT_GNTP_SERVER:   ${HUBOT_GNTP_SERVER}
  HUBOT_GNTP_PASSWORD: ***${HUBOT_GNTP_PASWORD:6}

hubot-gmail-growl:
  HUBOT_GMAIL_USERNAME:       ${HUBOT_GMAIL_USERNAME}
  HUBOT_GMAIL_PASSWORD:       ***********${HUBOT_GMAIL_PASSWORD:7}
  HUBOT_GMAIL_LABEL:          ${HUBOT_GMAIL_LABEL}
  HUBOT_GMAIL_CHECK_INTERVAL: ${HUBOT_GMAIL_CHECK_INTERVAL}
  HUBOT_IMAP_PROXY_SERVER:    ${HUBOT_IMAP_PROXY_SERVER}
  HUBOT_IMAP_PROXY_PORT:      ${HUBOT_IMAP_PROXY_PORT}

hubot-slack-growl:
  HUBOT_SLACK_MYNAME:         ${HUBOT_SLACK_MYNAME}
  HUBOT_SLACK_KEYWORDS:       ${HUBOT_SLACK_KEYWORDS}
#################################
EOF

exec "$@"
