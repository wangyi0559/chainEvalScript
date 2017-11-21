#!/bin/sh	
# author:wang yi

#orderer ip
ORDERER_IP=$(cat /chain/IP_ORDERER)
#ORDERER_IP="192.168.100.6"

function restartNetwork(){
    NETWORK_ID=$(docker network ls | grep "artifacts_default" | awk '{print $1}')
        if [ -z "$NETWORK_ID" -o "$NETWORK_ID" = " " ]; then
            docker network create -d bridge --ipv6=false artifacts_default >/dev/null 2>&1
        fi  
}
function checkPeer(){
    restartNetwork
	DOCKER_IMAGE_ID=$(docker images | grep "registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-peer" | awk '{print $3}')
        if [ -z "$DOCKER_IMAGE_ID" -o "$DOCKER_IMAGE_ID" = " " ]; then
		    docker pull registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-peer:v1.0.0 >/dev/null 2>&1
        fi
	DOCKER_IMAGE_ID=$(docker images | grep "hyperledger/fabric-ccenv" | awk '{print $3}')
        if [ -z "$DOCKER_IMAGE_ID" -o "$DOCKER_IMAGE_ID" = " " ]; then
		    docker pull registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-ccenv:x86_64-1.0.0 >/dev/null 2>&1
			docker tag registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-ccenv:x86_64-1.0.0 hyperledger/fabric-ccenv:x86_64-1.0.0 >/dev/null 2>&1
			docker rmi registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-ccenv:x86_64-1.0.0 >/dev/null 2>&1
        fi
	DOCKER_IMAGE_ID=$(docker images | grep "hyperledger/fabric-baseos" | awk '{print $3}')
        if [ -z "$DOCKER_IMAGE_ID" -o "$DOCKER_IMAGE_ID" = " " ]; then
		    docker pull registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-baseos:x86_64-0.3.1 >/dev/null 2>&1
			docker tag registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-baseos:x86_64-0.3.1 hyperledger/fabric-baseos:x86_64-0.3.1 >/dev/null 2>&1
			docker rmi registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-baseos:x86_64-0.3.1 >/dev/null 2>&1
        fi
}
function startP1O2(){
	checkPeer
    CONTAINER_ID=$(docker ps -a | grep "peer1.org2.example.com" | awk '{print $1}')
        if [ ! -z "$CONTAINER_ID" -o "$CONTAINER_ID" = " " ]; then
            docker rm -f $CONTAINER_ID >/dev/null 2>&1
        fi      
    docker run -d \
	--restart=always \
	-e CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock \
	-e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=artifacts_default \
   	-e CORE_PEER_GOSSIP_USELEADERELECTION=true \
	-e CORE_PEER_GOSSIP_ORGLEADER=false \
	-e CORE_PEER_GOSSIP_SKIPHANDSHAKE=true \
	-e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/crypto/peer/msp \
	-e CORE_PEER_TLS_ENABLED=true \
	-e CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/crypto/peer/tls/server.key \
	-e CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/crypto/peer/tls/server.crt \
	-e CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/crypto/peer/tls/ca.crt  \
	-v /var/run/:/host/var/run/ \
	-w /opt/gopath/src/github.com/hyperledger/fabric/peer \
	--add-host "orderer.example.com:$ORDERER_IP" \
	--network=artifacts_default \
	--name peer1.org2.example.com \
	-e CORE_PEER_ID=peer1.org2.example.com \
	-e CORE_PEER_LOCALMSPID=Org2MSP \
	-e CORE_PEER_ADDRESS=peer1.org2.example.com:7051 \
	-p 7051:7051 \
	-p 7053:7053 \
	-e CORE_LOGGING_LEVEL=DEBUG \
	-v /chain/channel/crypto-config/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/:/etc/hyperledger/crypto/peer \
	registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-peer:v1.0.0 \
	peer node start >/dev/null 2>&1
}
startP1O2
sleep 10s
/bin/bash /chain/chainEvalScript/fabricExample124/start/fabric_sdk_start.sh >/dev/null 2>&1
sleep 2s
echo "peer1.org2.example.com" > /chain/CONTAINER_NAME
docker ps -a | grep " peer1.org2.example.com" | awk '{print $1}' > /chain/CONTAINER_ID