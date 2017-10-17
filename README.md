Dockefile of hyperhq/hyper-devops
==============================================

run hubot in container. 

REF image: jordan/hubot-slack

# dependency

- hubot
  - adapter: slack
- npm module:
  - hubot-slack
  - hubot-hyper-devops
  - hubot-gmail-growl
- slack
  - HUBOT_SLACK_TOKEN
- hyper cli
  - HYPER_ACCESS_KEY
  - HYPER_SECRET_KEY
- gntp-send
  - GNTP_SERVER
  - GNTP_PASSWORD
- proxychains-ng
  - PROXY_PROTOCOL
  - PROXY_SERVER
  - PROXY_PORT
- inbox(gmail)
  - HUBOT_GMAIL_USERNAME
  - HUBOT_GMAIL_PASSWORD
  - HUBOT_GMAIL_LABEL
  - HUBOT_GMAIL_CHECK_INTERVAL

# build docker image

```
./build.sh
```

# crete slack token for hubot
go to `app directory` of slack, find `hubot`, config for hubot.
an API Token will be generated, like `xoxb-xxxxxx`

# Usage

## run hubot via docker

```
export HUBOT_SLACK_TOKEN=xoxb-xxx-yyy
export HYPER_ACCESS_KEY=xxxxx
export HYPER_SECRET_KEY=xxxxxxxxxxx
export EXTERNAL_SCRIPTS="hubot-help,hubot-hyper-devops"

// start by manual
$ docker run --name "hubot" \
-e HUBOT_NAME="hubot" \
-e HUBOT_OWNER="jimmy" \
-e EXTERNAL_SCRIPTS="$EXTERNAL_SCRIPTS" \
-e HUBOT_SLACK_TOKEN="$HUBOT_SLACK_TOKEN" \
-e HYPER_ACCESS_KEY="$HYPER_ACCESS_KEY"   -e HYPER_SECRET_KEY="$HYPER_SECRET_KEY" \
-e http_proxy="$http_proxy" \
-e https_proxy="$https_proxy" \
-it --rm \
hyperhq/hyper-devops:latest /bin/bash

//install external module
hubot@aeee20ea4921:~$ node -e "console.log(JSON.stringify('$EXTERNAL_SCRIPTS'.split(',')))" > external-scripts.json && npm install $(node -e "console.log('$EXTERNAL_SCRIPTS'.split(',').join(' '))")

//start hubot without slack
hubot@aeee20ea4921:~$ HUBOT_LOG_LEVEL=debug  bin/hubot -n $HUBOT_NAME

//start hubot with slack
hubot@aeee20ea4921:~$ HUBOT_LOG_LEVEL=debug  bin/hubot -n $HUBOT_NAME --adapter slack
```

```
// start as daemon
$ docker run --name "hubot" \
-e HUBOT_NAME="hubot" \
-e HUBOT_OWNER="jimmy" \
-e EXTERNAL_SCRIPTS="$EXTERNAL_SCRIPTS" \
-e HUBOT_SLACK_TOKEN="$HUBOT_SLACK_TOKEN" \
-e HYPER_ACCESS_KEY="$HYPER_ACCESS_KEY"   -e HYPER_SECRET_KEY="$HYPER_SECRET_KEY" \
-e HUBOT_GNTP_SERVER="$GNTP_SERVER" -e HUBOT_GNTP_PASSWORD="$GNTP_PASSWORD" \
-e http_proxy="$http_proxy" \
-e https_proxy="$https_proxy" \
-d \
hyperhq/hyper-devops:latest
```

## run hubot via hyper

- no public ip required
- no port required
- no gntp-send support

```
$ hyper run -d --name "hubot" \
  --restart=always \
  -e HUBOT_NAME="hubot" \
  -e HUBOT_OWNER="jimmy" \
  -e EXTERNAL_SCRIPTS="$EXTERNAL_SCRIPTS" \
  -e HUBOT_SLACK_TOKEN="$HUBOT_SLACK_TOKEN" \
  -e HYPER_ACCESS_KEY="${HYPER_ACCESS_KEY}"   -e HYPER_SECRET_KEY="${HYPER_SECRET_KEY}" \
 hyperhq/hyper-devops:latest

$ hyper update --protection=true hubot
```

## run hubot with hubot-gmail-growl

check new gmail, then notify growl via gntp-send

```
export EXTERNAL_SCRIPTS="hubot-help,hubot-gmail-growl"
export HUBOT_GMAIL_USERNAME="jimmy@hyper.sh"
export HUBOT_GMAIL_PASSWORD="xxxxxx"
export HUBOT_GMAIL_LABEL="To Me"
export HUBOT_GMAIL_CHECK_INTERVAL="5"
export HUBOT_GNTP_SERVER="192.168.1.23"
export HUBOT_GNTP_PASSWORD="xxxxxx"
export PROXY_PROTOCOL="socks5"
export PROXY_SERVER="192.168.1.137"
export PROXY_PORT="1080"

$ docker run --name "hubot-growl" \
  -e HUBOT_NAME="hubot" \
  -e HUBOT_OWNER="jimmy" \
  -e EXTERNAL_SCRIPTS="$EXTERNAL_SCRIPTS" \
  -e HUBOT_GNTP_SERVER="${HUBOT_GNTP_SERVER}" -e HUBOT_GNTP_PASSWORD="${HUBOT_GNTP_PASSWORD}" \
  -e HUBOT_GMAIL_USERNAME="$HUBOT_GMAIL_USERNAME" -e HUBOT_GMAIL_PASSWORD="$HUBOT_GMAIL_PASSWORD" \
  -e HUBOT_GMAIL_LABEL="$HUBOT_GMAIL_LABEL" -e HUBOT_GMAIL_CHECK_INTERVAL="$HUBOT_GMAIL_CHECK_INTERVAL" \
  -e PROXY_PROTOCOL="$PROXY_PROTOCOL" -e PROXY_SERVER="$PROXY_SERVER" -e PROXY_PORT="$PROXY_PORT" \
  -it --rm \
 hyperhq/hyper-devops:latest /bin/bash

//run then following command in container(use proxy to receive gmail) 
node -e "console.log(JSON.stringify('$EXTERNAL_SCRIPTS'.split(',')))" > external-scripts.json && npm install $(node -e "console.log('$EXTERNAL_SCRIPTS'.split(',').join(' '))")
HUBOT_LOG_LEVEL=debug proxychains4 -q bin/hubot -n $HUBOT_NAME


//example for use socks5
export PROXY_PROTOCOL="http"
export PROXY_SERVER="192.168.1.137"
export PROXY_PORT="8118"
```

# invite hubot in slack channel

input message in slack channel(for example #devops-hubot):

```
/invite @hubot
```

# send message in slack

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
