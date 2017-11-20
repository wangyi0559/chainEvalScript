#!/bin/bash
# author:wang yi
#根据不同测评实例，修改
#getEvalExample(由被测对象提供获取区块链方法)
#configEvalScript(测评系统根据被测对象提供的方法进行包装)

#参数传入zabbix server ip
SERVER_IP=$1

#zabbix agent ip
AGENT_IP=`ifconfig  | grep 'inet addr:' | grep -v '127.0.0.1' | grep -v '0.0.0.0' | grep -v '172.' | cut -d: -f2 | awk '{ print $1}'`
#创建/chain目录
if [ ! -d "/chain" ]; then
  mkdir /chain
fi
#创建/chain/netdat文件
if [ ! -f "/chain/netdat" ]; then
    touch /chain/netdat
fi
#保存IP
echo $SERVER_IP > /chain/SERVER_IP
echo $AGENT_IP > /chain/AGENT_IP
#执行网络监控
function startNetItem(){
    #获得网卡名称
    ETH_ID=$(ifconfig -s | awk '{print $1}' | grep "^e")
    #后台运行tcpdump，监控网卡，并将结果输出至/chain/netdat
    nohup tcpdump -qtn  -i $ETH_ID 'tcp port not 22 and port not 10050 and port not 10051 and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)' > /chain/netdat 2>&1 &
}
#启动并初始化zabbix-agent
function startZabbixAgent(){
    #下载最新zabbix-agent、agent初始化镜像
    docker pull registry.cn-hangzhou.aliyuncs.com/wangyi0559/zabbix-agent:1-1-4 
    docker pull registry.cn-hangzhou.aliyuncs.com/wangyi0559/eval-init 
    #关掉已存在zabbix-agent容器
    CONTAINER_ID=$(docker ps -a | grep "zabbix-agent" | awk '{print $1}')
        if [ ! -z "$CONTAINER_ID" -o "$CONTAINER_ID" = " " ]; then
                docker rm -f $CONTAINER_ID 
        fi
    #启动zabbix-agent容器
    docker run --privileged=true \
    --name zabbix-agent \
    --network=host \
    -e ZBX_HOSTNAME=$AGENT_IP \
    -e ZBX_SERVER_PORT=10051 \
    -e ZBX_SERVER_HOST=$SERVER_IP \
    -e ZBX_UNSAFEUSERPARAMETERS=1 \
    -e ZBX_ENABLEREMOTECOMMANDS=1 \
    -v /dev/sdc:/dev/sdc \
    -v /chain:/chain \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /var/lib/docker:/var/lib/docker \
    -d registry.cn-hangzhou.aliyuncs.com/wangyi0559/zabbix-agent:1-1-4 
    #暂停10s
    sleep 10s
    #初始化agent
    docker run --rm --privileged=true \
    --network=host \
    -d registry.cn-hangzhou.aliyuncs.com/wangyi0559/eval-init /bin/bash /init.sh $SERVER_IP $AGENT_IP 
}
#获取及配置区块链
function getEvalExample(){
    #安装git、tcpdump
    apt-get update 
    apt-get install -y -qq git tcpdump
    #git克隆工程
    cd /chain
    git clone https://github.com/wangyi0559/chainEvalScript.git 
    #移动需要文件
    mv /chain/chainEvalScript/yuelian/fabric/config/config.json /chain/config.json 
    mv /chain/chainEvalScript/yuelian/fabric/config/channel /chain/channel 
    mv /chain/chainEvalScript/yuelian/fabric/chaincode/channel /chain/channel 

    #docker 网络配置
    NETWORK_ID=$(docker network ls | grep "artifacts_default" | awk '{print $1}')
        if [ -z "$NETWORK_ID" -o "$NETWORK_ID" = " " ]; then
            docker network create -d bridge --ipv6=false artifacts_default 
        fi 
    #下载需要镜像
    #ca
    #docker pull registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-ca:v1.0.0 
    #orderer
    #docker pull registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-order:v1.0.0 
    #peer
    #docker pull registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-peer:v1.0.0 
    #docker pull registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-ccenv:x86_64-1.0.0 
	#docker tag registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-ccenv:x86_64-1.0.0 hyperledger/fabric-ccenv:x86_64-1.0.0 
	#docker rmi registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-ccenv:x86_64-1.0.0 
    #docker pull registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-baseos:x86_64-0.3.1 
	#docker tag registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-baseos:x86_64-0.3.1 hyperledger/fabric-baseos:x86_64-0.3.1 
	#docker rmi registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-baseos:x86_64-0.3.1 
    #sdk
    #docker pull registry.cn-hangzhou.aliyuncs.com/wangyi0559/eval:latest 
}
#配置相关执行脚本
function configEvalScript(){
    #/chain/Create.sh
    mv /chain/chainEvalScript/yuelian/Create.sh /chain/Create.sh
    cp /chain/Create.sh /chain/CreateTaskCommand.sh
    #/chain/Init.sh
    mv /chain/chainEvalScript/yuelian/Init.sh /chain/Init.sh
    cp /chain/Init.sh /chain/InitTaskCommand.sh
    #/chain/SendTransaction.sh
    mv /chain/chainEvalScript/yuelian/SendTransaction.sh /chain/SendTransaction.sh
    cp /chain/SendTransaction.sh /chain/SendTransactionTaskCommand.sh
    #/chain/ChangeStatus.sh
    mv /chain/chainEvalScript/yuelian/ChangeStatus.sh /chain/ChangeStatus.sh
    cp /chain/ChangeStatus.sh /chain/ChangeStatusTaskCommand.sh
    #/chain/DisConnection.sh
    mv /chain/chainEvalScript/yuelian/DisConnection.sh /chain/DisConnection.sh
    cp /chain/DisConnection.sh /chain/DisConnectionTaskCommand.sh
    #/chain/AssConnection.sh
    mv /chain/chainEvalScript/yuelian/AssConnection.sh /chain/AssConnection.sh
    cp /chain/AssConnection.sh /chain/AssConnectionTaskCommand.sh
}

sleep 2s
#获取及配置区块链
getEvalExample >/dev/null 2>&1
sleep 2s
#配置相关执行脚本
configEvalScript >/dev/null 2>&1
sleep 2s
#启动并初始化zabbix-agent
startZabbixAgent >/dev/null 2>&1
sleep 5s
#执行网络监控
startNetItem >/dev/null 2>&1
echo "succuss"