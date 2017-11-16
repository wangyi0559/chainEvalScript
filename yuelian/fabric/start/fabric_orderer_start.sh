#!/bin/sh	
# author:wang yi

function startOrder(){
	#检查是否有artifacts_default网络
	NETWORK_ID=$(docker network ls | grep "artifacts_default" | awk '{print $1}')
        if [ -z "$NETWORK_ID" -o "$NETWORK_ID" = " " ]; then
            docker network create -d bridge --ipv6=false artifacts_default 
        fi
	#检查镜像是否存在
	DOCKER_IMAGE_ID=$(docker images | grep "registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-order" | awk '{print $3}')
        if [ -z "$DOCKER_IMAGE_ID" -o "$DOCKER_IMAGE_ID" = " " ]; then
		    docker pull registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-order:v1.0.0 
        fi
	#删除已有同名容器
    CONTAINER_ID=$(docker ps -a | grep "orderer.example.com" | awk '{print $1}')
        if [ ! -z "$CONTAINER_ID" -o "$CONTAINER_ID" = " " ]; then
            docker rm -f $CONTAINER_ID 
        fi 
	#启动   
    docker run -d --name orderer.example.com \
	-e ORDERER_GENERAL_LISTENADDRESS=0.0.0.0 \
	-e ORDERER_GENERAL_GENESISMETHOD=file \
	-e ORDERER_GENERAL_GENESISFILE=/etc/hyperledger/configtx/genesis.block \
	-e ORDERER_GENERAL_LOCALMSPID=OrdererMSP \
	-e ORDERER_GENERAL_LOCALMSPDIR=/etc/hyperledger/crypto/orderer/msp \
	-e ORDERER_GENERAL_TLS_ENABLED=true \
	-e ORDERER_GENERAL_TLS_PRIVATEKEY=/etc/hyperledger/crypto/orderer/tls/server.key \
	-e ORDERER_GENERAL_TLS_CERTIFICATE=/etc/hyperledger/crypto/orderer/tls/server.crt \
	-e ORDERER_GENERAL_TLS_ROOTCAS=[/etc/hyperledger/crypto/orderer/tls/ca.crt,/etc/hyperledger/crypto/peerOrg1/tls/ca.crt] \
	-p 7050:7050 \
	-e ORDERER_GENERAL_LOGLEVEL=DEBUG \
    --network=artifacts_default \
	--privileged=true \
	-v /chain/channel:/etc/hyperledger/configtx \
	-v /chain/channel/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/:/etc/hyperledger/crypto/orderer \
	-v /chain/channel/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/:/etc/hyperledger/crypto/peerOrg1 \
	-w /opt/gopath/src/github.com/hyperledger/fabric/orderers \
	registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-order:v1.0.0 \
	orderer 
}
startOrder >/dev/null 2>&1
echo "success"