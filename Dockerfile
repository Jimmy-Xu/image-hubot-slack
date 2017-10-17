FROM node:latest
MAINTAINER Jimmy Xu <jimmy@hyper.sh>


################################
#  Install dependency package  #
################################
RUN npm install -g hubot coffee-script yo generator-hubot

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update &&\
    apt-get install -y vim &&\
    apt-get clean && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*


#######################
#  install hyper cli  #
#######################
RUN cd /usr/local/bin && \
    wget http://hyper-install.s3.amazonaws.com/hyper-linux-x86_64.tar.gz &&\
    tar xzvf hyper-linux-x86_64.tar.gz &&\
    rm -rf hyper-linux-x86_64.tar.gz

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


######################################################
# install proxychains-ng
######################################################
RUN cd /tmp && git clone https://github.com/rofl0r/proxychains-ng.git && cd proxychains-ng &&\
    ./configure --prefix=/usr --sysconfdir=/etc && \
    make && make install && make install-config && \
    sed -i "s/^socks4/#&/" /etc/proxychains.conf && \
    rm -rf /tmp/proxychains-ng


# PROXY_PROTOCOL could be socks5 or http
ENV PROXY_PROTOCOL=""
ENV PROXY_SERVER=""
ENV PROXY_PORT=""

######################################################
ADD entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

RUN useradd hubot -m
ENV PROXY_CONFIG="/home/hubot/proxychains.conf"
RUN mv /etc/proxychains.conf /home/hubot/ &&\
 ln -s $PROXY_CONFIG /etc/proxychains.conf &&\
 chown hubot:hubot $PROXY_CONFIG

USER hubot
WORKDIR /home/hubot

######################################################
## env for hubot
ENV HUBOT_NAME=${HUBOT_NAME:-myhubot}
ENV HUBOT_OWNER=${HUBOT_OWNER:-none}
ENV HUBOT_DESCRIPTION=${HUBOT_DESCRIPTION:-Hubot}

## env for hypercli
ENV HYPER_ACCESS_KEY ""
ENV HYPER_SECRET_KEY ""
ENV API_ROUTER ""
ENV REGION ""

## env for slack
ENV HUBOT_SLACK_TOKEN=${HUBOT_SLACK_TOKEN:-nope-1234-5678-91011-00e4dd}

## env for gntp-send
ENV HUBOT_GNTP_SERVER ""
ENV HUBOT_GNTP_PASSWORD ""

######################################################
RUN yo hubot --owner="${HUBOT_OWNER}" --name="${HUBOT_NAME}" --description="${HUBOT_DESCRIPTION}" --defaults &&\
    sed -i /heroku/d ./external-scripts.json &&\
		sed -i /redis-brain/d ./external-scripts.json &&\
		npm install hubot-scripts hubot-script-shellcmd &&\
		cp -R ./node_modules/hubot-script-shellcmd/bash . &&\
		npm install hubot-slack --save

VOLUME ["/home/hubot/scripts"]

ENV EXTERNAL_SCRIPTS "hubot-help,hubot-hyper-devops"
CMD node -e "console.log(JSON.stringify('$EXTERNAL_SCRIPTS'.split(',')))" > external-scripts.json && \
	npm install $(node -e "console.log('$EXTERNAL_SCRIPTS'.split(',').join(' '))") && \
	bin/hubot -n $HUBOT_NAME --adapter slack

