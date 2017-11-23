#!/bin/sh	
# author:wang yi

#启动
function startCA1(){
	#检查是否有artifacts_default网络
    NETWORK_ID=$(docker network ls | grep "artifacts_default" | awk '{print $1}')
        if [ -z "$NETWORK_ID" -o "$NETWORK_ID" = " " ]; then
            docker network create -d bridge --ipv6=false artifacts_default 
        fi
    #检查镜像是否存在
    DOCKER_IMAGE_ID=$(docker images | grep "registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-ca" | awk '{print $3}')
        if [ -z "$DOCKER_IMAGE_ID" -o "$DOCKER_IMAGE_ID" = " " ]; then
		    docker pull registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-ca:v1.0.0 
        fi
    #删除已有同名容器
    CONTAINER_ID=$(docker ps -a | grep "ca_peerOrg1" | awk '{print $1}')
        if [ ! -z "$CONTAINER_ID" -o "$CONTAINER_ID" = " " ]; then
            docker rm -f $CONTAINER_ID 
        fi    
    #启动  
    docker run -d \
	-e FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server \
	-e FABRIC_CA_SERVER_CA_CERTFILE=/etc/hyperledger/fabric-ca-server-config/ca.org1.example.com-cert.pem \
	-e FABRIC_CA_SERVER_CA_KEYFILE=/etc/hyperledger/fabric-ca-server-config/4b1c13ba5204b268baf2729762baf410310081d2685c2013c8daec28cec275b5_sk \
	-e FABRIC_CA_SERVER_TLS_ENABLED=true \
	-e FABRIC_CA_SERVER_TLS_CERTFILE=/etc/hyperledger/fabric-ca-server-config/ca.org1.example.com-cert.pem \
	-e FABRIC_CA_SERVER_TLS_KEYFILE=/etc/hyperledger/fabric-ca-server-config/4b1c13ba5204b268baf2729762baf410310081d2685c2013c8daec28cec275b5_sk \
	-p 7054:7054 \
    -e CORE_LOGGING_LEVEL=DEBUG \
    --network=artifacts_default \
	--privileged=true \
	-v /chain/channel/crypto-config/peerOrganizations/org1.example.com/ca/:/etc/hyperledger/fabric-ca-server-config \
	--name ca_peerOrg1 \
	registry.cn-hangzhou.aliyuncs.com/wangyi0559/fabric-ca:v1.0.0 \
	sh -c 'fabric-ca-server start -b admin:adminpw -d' 
}
startCA1 >/dev/null 2>&1
sleep 2s
echo "ca_peerOrg1" > /chain/CONTAINER_NAME
ls /var/lib/docker/containers | grep `docker ps -a | grep "ca_peerOrg1" | awk '{print $1}'` > /chain/CONTAINER_ID
echo "success"