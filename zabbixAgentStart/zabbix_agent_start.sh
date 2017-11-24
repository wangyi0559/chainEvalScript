#!/bin/bash
# author:wang yi

#zabbix server ip
SERVER_IP=$1

#zabbix agent ip
AGENT_IP=`ifconfig  | grep 'inet addr:' | grep -v '127.0.0.1' | grep -v '0.0.0.0' | grep -v '172.' | cut -d: -f2 | awk '{ print $1}'`

if [ ! -d "/chain" ]; then
  mkdir /chain
fi

echo $SERVER_IP > /chain/SERVER_IP
echo $AGENT_IP > /chain/AGENT_IP
touch /chain/netdat
#根据不同测评实例，修改
#getEvalExample(由被测对象提供获取区块链方法)
#configEvalScript(测评系统根据被测对象提供的方法进行包装)

function stopZabbixAgent(){
    CONTAINER_ID=$(docker ps -a | grep "zabbix-" | awk '{print $1}')
        if [ ! -z "$CONTAINER_ID" -o "$CONTAINER_ID" = " " ]; then
                docker rm -f $CONTAINER_ID >/dev/null 2>&1
        fi
}
function checkZabbixAgent(){
		docker pull registry.cn-hangzhou.aliyuncs.com/wangyi0559/zabbix-agent:latest >/dev/null 2>&1
}
function startZabbixAgent(){
    checkZabbixAgent
    stopZabbixAgent
    docker run --privileged=true \
    --restart=always \
    --name zabbix-agent \
    --network=host \
    -e ZBX_HOSTNAME=$AGENT_IP \
    -e ZBX_SERVER_PORT=10051 \
    -e ZBX_SERVER_HOST=$SERVER_IP \
    -e ZBX_UNSAFEUSERPARAMETERS=1 \
    -e ZBX_ENABLEREMOTECOMMANDS=1 \
    -e ZBX_TIMEOUT=30 \
    -v /dev/sdc:/dev/sdc \
    -v /chain:/chain \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /var/lib/docker:/var/lib/docker \
    -d registry.cn-hangzhou.aliyuncs.com/wangyi0559/zabbix-agent:latest >/dev/null 2>&1
}
function checkEvalInit(){
	    docker pull registry.cn-hangzhou.aliyuncs.com/wangyi0559/eval-init >/dev/null 2>&1
}
function initZabbix(){
    checkEvalInit
    docker run --rm --privileged=true \
    --network=host \
    -d registry.cn-hangzhou.aliyuncs.com/wangyi0559/eval-init /bin/bash /init.sh $SERVER_IP $AGENT_IP >/dev/null 2>&1
}

function getEvalExample(){
    #安装git
    apt-get update >/dev/null 2>&1
    apt-get install -y -qq git tcpdump >/dev/null 2>&1
    #git克隆工程
    cd /chain
    git clone https://github.com/wangyi0559/chainEvalScript.git >/dev/null 2>&1
    #移动需要文件
    mv /chain/chainEvalScript/fabricExample124/config/config.json /chain/config.json >/dev/null 2>&1
    mv /chain/chainEvalScript/fabricExample124/config/channel /chain/channel >/dev/null 2>&1

    #docker 网络配置
    NETWORK_ID=$(docker network ls | grep "artifacts_default" | awk '{print $1}')
        if [ -z "$NETWORK_ID" -o "$NETWORK_ID" = " " ]; then
            docker network create -d bridge --ipv6=false artifacts_default >/dev/null 2>&1
        fi 
    #下载需要镜像
    #ca
    docker pull registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-ca:v1.0.0 >/dev/null 2>&1
    #orderer
    docker pull registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-order:v1.0.0 >/dev/null 2>&1
    #peer
    docker pull registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-peer:v1.0.0 >/dev/null 2>&1
    docker pull registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-ccenv:x86_64-1.0.0 >/dev/null 2>&1
	docker tag registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-ccenv:x86_64-1.0.0 hyperledger/fabric-ccenv:x86_64-1.0.0 >/dev/null 2>&1
	docker rmi registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-ccenv:x86_64-1.0.0 >/dev/null 2>&1
    docker pull registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-baseos:x86_64-0.3.1 >/dev/null 2>&1
	docker tag registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-baseos:x86_64-0.3.1 hyperledger/fabric-baseos:x86_64-0.3.1 >/dev/null 2>&1
	docker rmi registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-baseos:x86_64-0.3.1 >/dev/null 2>&1
    #sdk
    docker pull registry.cn-hangzhou.aliyuncs.com/wangyi0559/eval:latest >/dev/null 2>&1
    #init
    docker pull registry.cn-hangzhou.aliyuncs.com/wangyi0559/eval-init >/dev/null 2>&1
}
function configEvalScript(){
    #/chain/Create.sh
    mv /chain/chainEvalScript/fabricExample124/Create.sh /chain/Create.sh
    cp /chain/Create.sh /chain/CreateTaskCommand.sh

    #/chain/Init.sh
    mv /chain/chainEvalScript/fabricExample124/Init.sh /chain/Init.sh
    cp /chain/Init.sh /chain/InitTaskCommand.sh

    #/chain/SendTransaction.sh
    mv /chain/chainEvalScript/fabricExample124/SendTransaction.sh /chain/SendTransaction.sh
    cp /chain/SendTransaction.sh /chain/SendTransactionTaskCommand.sh

    #/chain/ChangeStatus.sh
    mv /chain/chainEvalScript/fabricExample124/ChangeStatus.sh /chain/ChangeStatus.sh
    cp /chain/ChangeStatus.sh /chain/ChangeStatusTaskCommand.sh

    #/chain/DisConnection.sh
    mv /chain/chainEvalScript/fabricExample124/DisConnection.sh /chain/DisConnection.sh
    cp /chain/DisConnection.sh /chain/DisConnectionTaskCommand.sh

    #/chain/AssConnection.sh
    mv /chain/chainEvalScript/fabricExample124/AssConnection.sh /chain/AssConnection.sh
    cp /chain/AssConnection.sh /chain/AssConnectionTaskCommand.sh
}
function startNetItem(){
    ETH_ID=$(ifconfig -s | awk '{print $1}' | grep "^e")
    nohup tcpdump -qtn  -i $ETH_ID 'tcp port not 22 and port not 10050 and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)' > /chain/netdat 2>&1 &
}

sleep 5s
getEvalExample
sleep 5s
configEvalScript
sleep 5s
startZabbixAgent
sleep 10s
initZabbix
sleep 5s
startNetItem
echo "succuss"