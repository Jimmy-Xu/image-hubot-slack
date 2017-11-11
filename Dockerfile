FROM node:latest
MAINTAINER Jimmy Xu <jimmy@hyper.sh>

RUN useradd hubot -m
ENV WORK_DIR=/home/hubot

###################################################
# Install dependency package                      #
#   proxy:  shadowsocks, privoxy, proxychains-ng  #
###################################################
RUN npm install -g hubot coffee-script yo generator-hubot

ENV DEBIAN_FRONTEND noninteractive

# common package, shadowsocks and privoxy
RUN apt-get update &&\
    apt-get install -y vim screen net-tools python-pip privoxy &&\
    pip install shadowsocks && mkdir /etc/shadowsocks &&\
    apt-get clean && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

# proxychains-ng
RUN cd /tmp && git clone https://github.com/rofl0r/proxychains-ng.git && cd proxychains-ng &&\
    ./configure --prefix=/usr --sysconfdir=/etc && \
    make && make install && make install-config && \
    rm -rf /tmp/proxychains-ng


###############################
#  add config file for proxy  #
###############################
ENV PROXYCHAINS_CONF="$WORK_DIR/etc/proxychains.conf"
ENV PRIVOXY_CONF="$WORK_DIR/etc/privoxy.conf"
ENV SSLOCAL_CONF="$WORK_DIR/etc/sslocal.conf"
COPY etc /etc/
RUN mkdir -p $WORK_DIR/etc && chown hubot:hubot $WORK_DIR/etc &&\
    mv /etc/proxychains.conf $PROXYCHAINS_CONF &&\
    ln -s $PROXYCHAINS_CONF /etc/proxychains.conf &&\
    \
    mv /etc/privoxy/config $PRIVOXY_CONF &&\
    ln -s $PRIVOXY_CONF /etc/privoxy/config &&\
    \
    mv /etc/shadowsocks/client.json $SSLOCAL_CONF &&\
    ln -s $SSLOCAL_CONF /etc/shadowsocks/client.json &&\
    \
    ln -s $WORK_DIR/entrypoint.sh /usr/local/bin/entrypoint.sh &&\
    \
    chown hubot:hubot $PROXYCHAINS_CONF $SSLOCAL_CONF $PRIVOXY_CONF

#######################
#  install gntp-send  #
#######################
RUN cd /opt/ &&\
    git clone https://github.com/mattn/gntp-send.git &&\
    cd gntp-send &&\
    ./autogen.sh &&\
    ./configure &&\
    make &&\
    ./gntp-send || echo -n &&\
    cp .libs/lt-gntp-send /usr/local/bin/gntp-send -rf

#######################
#  install hyper cli  #
#######################
RUN cd /usr/local/bin && \
    wget http://hyper-install.s3.amazonaws.com/hyper-linux-x86_64.tar.gz &&\
    tar xzvf hyper-linux-x86_64.tar.gz &&\
    rm -rf hyper-linux-x86_64.tar.gz


##############################################################
# ENV for hubot, hypercli, slack, gntp-send, hubot-gmail-growl
##############################################################
## hubot
ENV HUBOT_NAME=${HUBOT_NAME:-myhubot}
ENV HUBOT_OWNER=${HUBOT_OWNER:-none}
ENV HUBOT_DESCRIPTION=${HUBOT_DESCRIPTION:-Hubot}

## hypercli
ENV HYPER_ACCESS_KEY=""
ENV HYPER_SECRET_KEY=""
ENV API_ROUTER="${API_ROUTER:-tcp://us-west-1.hyper.sh:443}"
ENV REGION="${REGION:-us-west-1}"

## slack
ENV HUBOT_SLACK_TOKEN=${HUBOT_SLACK_TOKEN:-nope-1234-5678-91011-00e4dd}

## gntp-send
ENV HUBOT_GNTP_SERVER=""
ENV HUBOT_GNTP_PASSWORD=""

## hubot-gmail-growl
ENV HUBOT_GMAIL_USERNAME=""
ENV HUBOT_GMAIL_PASSWORD=""
ENV HUBOT_GMAIL_LABEL=""
ENV HUBOT_GMAIL_CHECK_INTERVAL=""
ENV HUBOT_IMAP_PROXY_SERVER=""
ENV HUBOT_IMAP_PROXY_PORT="${HUBOT_IMAP_PROXY_PORT:-5993}"

## hubot-slack-growl
ENV HUBOT_SLACK_MYNAME=""
ENV HUBOT_SLACK_KEYWORDS=""

## hubot-another-weixin
ENV HUBOT_WATCH_GROUPS=""
ENV HUBOT_WATCH_GH=""
ENV HUBOT_WATCH_USERS="文件传输助手"
ENV WX_COOKIE=""
ENV WX_UIN=""
ENV WX_SID=""
ENV WX_SKEY=""
ENV WX_DEVICEID=""

######################################################
# ENV for proxy
######################################################
## no proxy by default

#============================================
# solution1:
#   internal: ptunnel.py
#   external: http_proxy(privoxy)
#============================================
## external http proxy(Example: 192.168.1.137:8118)
ENV USE_EXT_HTTP_PROXY=${USE_EXT_HTTP_PROXY:-0}
ENV HTTP_PROXY_IP=""
ENV HTTP_PROXY_PORT=""

#====================================================================
# solution2:
#   internal: ptunnel.py, http_proxy(privoxy)
#   external: socks5_proxy(sslocal)
#====================================================================
## external sslocal (Example: 192.168.1.137:1080)
ENV USE_EXT_SSLOCAL=${USE_EXT_SSLOCAL:-0}
ENV SOCKS5_PROXY_IP=""
ENV SOCKS5_PROXY_PORT=""

#====================================================================
# solution3:
#   internal: ptunnel.py, http_proxy(privoxy), socks5_proxy(sslocal)
#   external: shadowsocks(ssserver)
#====================================================================
## external shadowsocks server
ENV USE_EXT_SSSERVER=${USE_EXT_SSSERVER:-0}
ENV SS_SERVER=""
ENV SS_PORT="${SS_PORT:-8338}"
ENV SS_PASSWORD=""
ENV SS_METHOD="${SS_METHOD:-aes-256-cfb}"


#######################
# change user and dir
#######################
USER hubot
WORKDIR ${WORK_DIR}


######################################################
RUN yo hubot --owner="${HUBOT_OWNER}" --name="${HUBOT_NAME}" --description="${HUBOT_DESCRIPTION}" --defaults &&\
    sed -i /heroku/d ./external-scripts.json &&\
		sed -i /redis-brain/d ./external-scripts.json &&\
		npm install hubot-scripts hubot-script-shellcmd &&\
		cp -R ./node_modules/hubot-script-shellcmd/bash . &&\
		npm install hubot-slack hubot-help hubot-hyper-devops hubot-gmail-growl hubot-slack-growl \
		 hubot-another-weixin xml2js --save

ENV EXTERNAL_SCRIPTS "hubot-help,hubot-hyper-devops,hubot-gmail-growl,hubot-slack-growl"
CMD node -e "console.log(JSON.stringify('$EXTERNAL_SCRIPTS'.split(',')))" > external-scripts.json && \
	npm install $(node -e "console.log('$EXTERNAL_SCRIPTS'.split(',').join(' '))") && \
	bin/hubot -n $HUBOT_NAME --adapter slack


######################################################
ENTRYPOINT ["entrypoint.sh"]
VOLUME ["$WORK_DIR/scripts"]

######################################################
# add customized script
######################################################
COPY script $WORK_DIR/
USER root
RUN cd $WORK_DIR && chown hubot:hubot ptunnel.* start.sh entrypoint.sh && chmod +x ptunnel.* start.sh entrypoint.sh
USER hubot
