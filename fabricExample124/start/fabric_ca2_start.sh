#!/bin/sh	
# author:wang yi

#检查是否有artifacts_default网络
function restartNetwork(){
    NETWORK_ID=$(docker network ls | grep "artifacts_default" | awk '{print $1}')
        if [ -z "$NETWORK_ID" -o "$NETWORK_ID" = " " ]; then
            docker network create -d bridge --ipv6=false artifacts_default >/dev/null 2>&1
        fi  
}
#检查镜像是否存在
function checkCA(){
    restartNetwork
    DOCKER_IMAGE_ID=$(docker images | grep "registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-ca" | awk '{print $3}')
        if [ -z "$DOCKER_IMAGE_ID" -o "$DOCKER_IMAGE_ID" = " " ]; then
		    docker pull registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-ca:v1.0.0 >/dev/null 2>&1
        fi
}
#启动
function startCA2(){
	checkCA
    CONTAINER_ID=$(docker ps -a | grep "ca_peerOrg2" | awk '{print $1}')
        if [ ! -z "$CONTAINER_ID" -o "$CONTAINER_ID" = " " ]; then
            docker rm -f $CONTAINER_ID >/dev/null 2>&1
        fi       
    docker run -d \
    --restart=always \
	-e FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server \
	-e FABRIC_CA_SERVER_CA_CERTFILE=/etc/hyperledger/fabric-ca-server-config/ca.org2.example.com-cert.pem \
	-e FABRIC_CA_SERVER_CA_KEYFILE=/etc/hyperledger/fabric-ca-server-config/a7d47efa46a6ba07730c850fed2c1375df27360d7227f48cdc2f80e505678005_sk \
	-e FABRIC_CA_SERVER_TLS_ENABLED=true \
	-e FABRIC_CA_SERVER_TLS_CERTFILE=/etc/hyperledger/fabric-ca-server-config/ca.org2.example.com-cert.pem \
	-e FABRIC_CA_SERVER_TLS_KEYFILE=/etc/hyperledger/fabric-ca-server-config/a7d47efa46a6ba07730c850fed2c1375df27360d7227f48cdc2f80e505678005_sk \
	-p 7055:7054 \
    -e CORE_LOGGING_LEVEL=DEBUG \
    --network=artifacts_default \
	--privileged=true \
	-v /chain/channel/crypto-config/peerOrganizations/org2.example.com/ca/:/etc/hyperledger/fabric-ca-server-config \
	--name ca_peerOrg2 \
	registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-ca:v1.0.0 \
	sh -c 'fabric-ca-server start -b admin:adminpw -d' >/dev/null 2>&1
}
startCA2
sleep 2s
echo "ca_peerOrg2" > /chain/CONTAINER_NAME
ls /var/lib/docker/containers | grep `docker ps -a | grep "ca_peerOrg2" | awk '{print $1}'` > /chain/CONTAINER_ID