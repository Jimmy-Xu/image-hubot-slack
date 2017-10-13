Dockefile of hyperhq/hyper-devops
==============================================

run hubot in container. 

REF image: jordan/hubot-slack

# dependency

- hubot
- npm module: hubot-slack, hubot-hyper-devops
- hyper cli
- gntp-send

# build docker image

```
./build.sh
```

# crete slack token for hubot
go to `app directory` of slack, find `hubot`, config for hubot.
an API Token will be generated, like `xoxb-xxxxxx`

# run hubot via docker

```
export SLACK_TOKEN=xoxb-xxx-yyy
export HYPER_ACCESS_KEY=xxxxx
export HYPER_SECRET_KEY=xxxxxxxxxxx
export GNTP_SERVER="192.168.1.23:23053"
export GNTP_PASSWORD="xxxxxx"

// start by manual
$ docker run -it --rm --name "hubot" \
-e HUBOT_NAME="hubot" \
-e HUBOT_OWNER="jimmy" \
-e EXTERNAL_SCRIPTS="hubot-help,hubot-hyper-devops" \
-e HUBOT_SLACK_TOKEN="${SLACK_TOKEN}" \
-e HYPER_ACCESS_KEY="${HYPER_ACCESS_KEY}"   -e HYPER_SECRET_KEY="${HYPER_SECRET_KEY}" \
-e HUBOT_GNTP_SERVER="${GNTP_SERVER}" -e HUBOT_GNTP_PASSWORD="${GNTP_PASSWORD}" \
-e http_proxy=${http_proxy} \
-e https_proxy=${https_proxy} \
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
$ docker run -d --name "hubot" \
-e HUBOT_NAME="hubot" \
-e HUBOT_OWNER="jimmy" \
-e EXTERNAL_SCRIPTS="hubot-help,hubot-hyper-devops" \
-e HUBOT_SLACK_TOKEN="${SLACK_TOKEN}" \
-e HYPER_ACCESS_KEY="${HYPER_ACCESS_KEY}"   -e HYPER_SECRET_KEY="${HYPER_SECRET_KEY}" \
-e HUBOT_GNTP_SERVER="${GNTP_SERVER}" -e HUBOT_GNTP_PASSWORD="${GNTP_PASSWORD}" \
-e http_proxy=${http_proxy} \
-e https_proxy=${https_proxy} \
hyperhq/hyper-devops:latest


```

# run hubot via hyper

- no public ip required
- no port required
- no gntp-send support

```
$ hyper run -d --name "hubot" \
  --restart=always \
  -e HUBOT_NAME="hubot" \
  -e HUBOT_OWNER="jimmy" \
  -e EXTERNAL_SCRIPTS=hubot-help,hubot-hyper-devops,hubot-script-shellcmd \
  -e HUBOT_SLACK_TOKEN="$SLACK_TOKEN" \
  -e HYPER_ACCESS_KEY="${HYPER_ACCESS_KEY}"   -e HYPER_SECRET_KEY="${HYPER_SECRET_KEY}" \
  -p 8080:8080 \
 hyperhq/hyper-devops:latest

$ hyper update --protection=true hubot
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
