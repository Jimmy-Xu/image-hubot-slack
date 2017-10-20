Dockefile of hyperhq/hyper-devops
==============================================

run hubot in container.

<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Summary](#summary)
	- [feature](#feature)
	- [dependency](#dependency)
	- [env](#env)
- [Build docker image](#build-docker-image)
- [Prepare](#prepare)
	- [Slack Token](#slack-token)
	- [Gmail Basic Auth](#gmail-basic-auth)
	- [Install Growl](#install-growl)
- [Usage](#usage)
	- [Use hyper-gmail-growl](#use-hyper-gmail-growl)
		- [without proxy](#without-proxy)
		- [use external http proxy](#use-external-http-proxy)
		- [use external socks5 proxy](#use-external-socks5-proxy)
		- [use external shadowsocks server](#use-external-shadowsocks-server)
	- [Use hubot-hyper-devops](#use-hubot-hyper-devops)
		- [run with docker](#run-with-docker)
		- [run with hyper](#run-with-hyper)
		- [send message in slack](#send-message-in-slack)
	- [Run hubot-slack-growl](#run-hubot-slack-growl)
- [invite hubot in slack channel](#invite-hubot-in-slack-channel)

<!-- /TOC -->

# Summary

## feature

- **hubot-hyper-devops**(plugin): execute hyper cli via slack
- **hubot-gmail-growl**(plugin): periodically check gmail, notify via growl


## dependency

- hubot
  - adapter: slack
- npm module:
  - adapter:
    - hubot-slack
  - plugin:
    - hubot-help
    - hubot-hyper-devops
    - hubot-gmail-growl

## env

- slack
  - HUBOT_SLACK_TOKEN
- hyper cli
  - HYPER_ACCESS_KEY
  - HYPER_SECRET_KEY
- gntp-send
  - GNTP_SERVER
  - GNTP_PASSWORD
- gmail-growl
  - HUBOT_GMAIL_USERNAME
  - HUBOT_GMAIL_PASSWORD
  - HUBOT_GMAIL_LABEL
  - HUBOT_GMAIL_CHECK_INTERVAL
  - HUBOT_GNTP_SERVER
  - HUBOT_GNTP_PASSWORD
  - HUBOT_IMAP_PROXY_SERVER
  - HUBOT_IMAP_PROXY_PORT
- for proxy
  - USE_EXT_HTTP_PROXY
    - HTTP_PROXY_IP
    - HTTP_PROXY_PORT
  - USE_EXT_SSLOCAL
    - SOCKS5_PROXY_IP
    - SOCKS5_PROXY_PORT
  - USE_EXT_SSSERVER
    - SS_SERVER
    - SS_PORT
    - SS_PASSWORD
    - SS_METHOD


# Build docker image

```
./build.sh
```


# Prepare

## Slack Token
crete slack token for hubot
go to `app directory` of slack, find `hubot`, config for hubot.
an API Token will be generated, like `xoxb-xxxxxx`

## Gmail Basic Auth

for basic auth, go to https://myaccount.google.com/security?pli=1#connectedapps, set "Allow less secure app" to "ON"


## Install Growl

- [Growl for Windows](http://www.growlforwindows.com/gfw/)
- [Growl for MacOSX](http://growl.info/)
- [Growl for Linux](https://github.com/mattn/growl-for-linux)

> Set a password for growl first.  
> The default port is 23053.


# Usage

## Use hyper-gmail-growl

Solution diagram  
![](doc/solution.png)

Notification effect  
![](doc/notification-gmail.png)

Notification history  
![](doc/growl-for-windows.png)


```bash
//env for gmail
export HUBOT_GMAIL_USERNAME="jimmy@hyper.sh"
export HUBOT_GMAIL_PASSWORD="xxxxxx"
export HUBOT_GMAIL_LABEL="To Me"
export HUBOT_GMAIL_CHECK_INTERVAL="5"

//for send notification via gntp-send[growl client]
export HUBOT_GNTP_SERVER="192.168.1.23"
export HUBOT_GNTP_PASSWORD="xxxxxx"
```

### without proxy

> gmail was blocked without proxy

```bash
docker run -it --rm \
    -e HUBOT_NAME="hubot" \
    -e EXTERNAL_SCRIPTS="hubot-help,hubot-gmail-growl" \
    -e HUBOT_GMAIL_USERNAME=$HUBOT_GMAIL_USERNAME -e HUBOT_GMAIL_PASSWORD=$HUBOT_GMAIL_PASSWORD \
    -e HUBOT_GMAIL_LABEL="$HUBOT_GMAIL_LABEL" -e HUBOT_GMAIL_CHECK_INTERVAL=$HUBOT_GMAIL_CHECK_INTERVAL \
    -e HUBOT_GNTP_SERVER=$HUBOT_GNTP_SERVER -e HUBOT_GNTP_PASSWORD=$HUBOT_GNTP_PASSWORD \
    hyperhq/hyper-devops bash
```

### use external http proxy

```bash
//imap proxy via http
export HTTP_PROXY_IP=192.168.1.137
export HTTP_PROXY_PORT=8118

//specify USE_EXT_HTTP_PROXY
docker run -it --rm \
    -e HUBOT_NAME="hubot" \
    -e EXTERNAL_SCRIPTS="hubot-help,hubot-gmail-growl" \
    -e USE_EXT_HTTP_PROXY=1 -e HTTP_PROXY_IP=$HTTP_PROXY_IP -e HTTP_PROXY_PORT=$HTTP_PROXY_PORT \
    -e HUBOT_GMAIL_USERNAME=$HUBOT_GMAIL_USERNAME -e HUBOT_GMAIL_PASSWORD=$HUBOT_GMAIL_PASSWORD \
    -e HUBOT_GMAIL_LABEL="$HUBOT_GMAIL_LABEL" -e HUBOT_GMAIL_CHECK_INTERVAL=$HUBOT_GMAIL_CHECK_INTERVAL \
    -e HUBOT_GNTP_SERVER=$HUBOT_GNTP_SERVER -e HUBOT_GNTP_PASSWORD=$HUBOT_GNTP_PASSWORD \
    hyperhq/hyper-devops bash

//run the following commands in docker container
./start.sh init
./start.sh imap_proxy


//run the following commands in hubot
> hubot gmail-growl start
...
[Thu Oct 19 2017 13:32:58 GMT+0000 (UTC)] INFO Initializing IMAP client...
Started the GMail fetch
[Thu Oct 19 2017 13:33:00 GMT+0000 (UTC)] INFO Message count in To Me: 17276
[Thu Oct 19 2017 13:33:00 GMT+0000 (UTC)] INFO Check it!
[Thu Oct 19 2017 13:33:01 GMT+0000 (UTC)] INFO Max UID: 17276
...
```

### use external socks5 proxy

```bash
export SOCKS5_PROXY_IP=192.168.1.137
export SOCKS5_PROXY_PORT=1080

//specify USE_EXT_SSLOCAL
docker run -it --rm \
    -e HUBOT_NAME="hubot" \
    -e EXTERNAL_SCRIPTS="hubot-help,hubot-gmail-growl" \
    -e USE_EXT_SSLOCAL=1 -e SOCKS5_PROXY_IP=$SOCKS5_PROXY_IP -e SOCKS5_PROXY_PORT=$SOCKS5_PROXY_PORT \
    -e HUBOT_GMAIL_USERNAME=$HUBOT_GMAIL_USERNAME -e HUBOT_GMAIL_PASSWORD=$HUBOT_GMAIL_PASSWORD \
    -e HUBOT_GMAIL_LABEL="$HUBOT_GMAIL_LABEL" -e HUBOT_GMAIL_CHECK_INTERVAL=$HUBOT_GMAIL_CHECK_INTERVAL \
    -e HUBOT_GNTP_SERVER=$HUBOT_GNTP_SERVER -e HUBOT_GNTP_PASSWORD=$HUBOT_GNTP_PASSWORD \
    hyperhq/hyper-devops bash

//run the following commands in docker container
./start.sh init
./start.sh imap_proxy
```

### use external shadowsocks server

```bash
export SS_SERVER=x.x.x.x
export SS_PORT=20171
export SS_PASSWORD=xxxxxx
export SS_METHOD=aes-256-cfb

//specify USE_EXT_SSSERVER
docker run -it --rm \
    -e HUBOT_NAME="hubot" \
    -e EXTERNAL_SCRIPTS="hubot-help,hubot-gmail-growl" \
    -e USE_EXT_SSSERVER=1 -e SS_SERVER=$SS_SERVER -e SS_PORT=$SS_PORT -e SS_PASSWORD=$SS_PASSWORD \
    -e HUBOT_GMAIL_USERNAME=$HUBOT_GMAIL_USERNAME -e HUBOT_GMAIL_PASSWORD=$HUBOT_GMAIL_PASSWORD \
    -e HUBOT_GMAIL_LABEL="$HUBOT_GMAIL_LABEL" -e HUBOT_GMAIL_CHECK_INTERVAL=$HUBOT_GMAIL_CHECK_INTERVAL \
    -e HUBOT_GNTP_SERVER=$HUBOT_GNTP_SERVER -e HUBOT_GNTP_PASSWORD=$HUBOT_GNTP_PASSWORD \
    hyperhq/hyper-devops bash

//run the following commands in docker container
./start.sh init
./start.sh imap_proxy
```


## Use hubot-hyper-devops

### run with docker

```bash
export HUBOT_SLACK_TOKEN=xoxb-xxx-yyy
export HYPER_ACCESS_KEY=xxxxx
export HYPER_SECRET_KEY=xxxxxxxxxxx

// start by manual
docker run -it --rm \
    -e HUBOT_NAME="hubot" \
    -e HUBOT_OWNER="jimmy" \
    -e EXTERNAL_SCRIPTS="hubot-help,hubot-hyper-devops,hubot-script-shellcmd" \
    -e HUBOT_SLACK_TOKEN="$HUBOT_SLACK_TOKEN" \
    -e HYPER_ACCESS_KEY="$HYPER_ACCESS_KEY"   -e HYPER_SECRET_KEY="$HYPER_SECRET_KEY" \
    -e http_proxy="$http_proxy" \
    -e https_proxy="$https_proxy" \
    hyperhq/hyper-devops:latest /bin/bash

//run the following commands in docker container
./start.sh init
./start.sh slack
```

### run with hyper

- no fip required
- no port required

```bash
// start as daemon
hyper run -d --name hubot-hyper-devops \
    -e HUBOT_NAME="hubot" \
    -e HUBOT_OWNER="jimmy" \
    -e EXTERNAL_SCRIPTS="hubot-help,hubot-hyper-devops,hubot-script-shellcmd" \
    -e HUBOT_SLACK_TOKEN="$HUBOT_SLACK_TOKEN" \
    -e HYPER_ACCESS_KEY="$HYPER_ACCESS_KEY"   -e HYPER_SECRET_KEY="$HYPER_SECRET_KEY" \
    hyperhq/hyper-devops:latest

hyper update --protection=true hubot-hyper-devops
```

### send message in slack

```
Jimmy Xu [20:05]
hubot help

hubotAPP [20:05]
hubot help - Displays all of the help commands that this bot knows about.
hubot help <query> - Displays all help commands that match <query>.
hubot hyper <arguments> - Run hyper cli command line
hubot shellcmd - list (bash)shell commands
hubot shellcmd <foo> - performs bashshell command


Jimmy Xu [20:05]
@hubot hyper -v

hubotAPP [04:30] 
Hyper version 1.10.16, build 860cca2


Jimmy Xu [20:05]
hubot shellcmd

hubotAPP [20:05]
available commands:
  helloworld
  update


Jimmy Xu [20:06]
hubot shellcmd helloworld

hubotAPP [20:06]
Hello..
Sleepy World!
```


## Run hubot-slack-growl

Notify to growl when matched slack message  
![](doc/notification-slack.png)

> hubot **adapter** should be `slack`

```bash
export HUBOT_SLACK_TOKEN=xoxb-24xxxxxxx96-GMNpFxxxxxxxxxxxxx7Vf

//for send notification via gntp-send[growl client]
export HUBOT_SLACK_MYNAME=jimmy
export HUBOT_SLACK_KEYWORDS="@jimmy,@channel,Jimmy Xu"
export HUBOT_GNTP_SERVER="192.168.1.23"
export HUBOT_GNTP_PASSWORD="xxxxxx"

docker run -it --rm \
    -e HUBOT_NAME="hubot" \
    -e HUBOT_OWNER="jimmy" \
    -e EXTERNAL_SCRIPTS="hubot-help,hubot-slack-growl" \
    -e HUBOT_SLACK_TOKEN="$HUBOT_SLACK_TOKEN" \
    -e HYPER_ACCESS_KEY="$HYPER_ACCESS_KEY" -e HYPER_SECRET_KEY="$HYPER_SECRET_KEY" \
    -e HUBOT_SLACK_MYNAME=$HUBOT_SLACK_MYNAME -e HUBOT_SLACK_KEYWORDS="$HUBOT_SLACK_KEYWORDS" \
    -e HUBOT_GNTP_SERVER=$HUBOT_GNTP_SERVER -e HUBOT_GNTP_PASSWORD=$HUBOT_GNTP_PASSWORD \
    -e http_proxy="$http_proxy" \
    -e https_proxy="$https_proxy" \
    hyperhq/hyper-devops:latest /bin/bash

//run the following commands in docker container
./start.sh init
./start.sh slack
```

# invite hubot in slack channel

input message in slack channel(for example #devops-hubot):

```
/invite @hubot
```

to view help, input : `@hubot help`


also, you can send direct message to hubot  
to view help in direct message, just input: `help`  
![](doc/hubot-direct-message.png)
