#!/bin/sh	
# author:wang yi

function startSDK(){
    #检查镜像是否存在
	DOCKER_IMAGE_ID=$(docker images | grep "registry.cn-hangzhou.aliyuncs.com/wangyi0559/eval" | awk '{print $3}')
        if [ -z "$DOCKER_IMAGE_ID" -o "$DOCKER_IMAGE_ID" = " " ]; then
		    docker pull registry.cn-hangzhou.aliyuncs.com/wangyi0559/eval:latest 
        fi
    #删除已有同名容器
    CONTAINER_ID=$(docker ps -a | grep "fabric-sdk" | awk '{print $1}')
        if [ ! -z "$CONTAINER_ID" -o "$CONTAINER_ID" = " " ]; then
            docker rm -f $CONTAINER_ID 
        fi  
    #启动 
    docker run -d \
	-v /chain/channel/:/home/Service/test/artifacts/channel/ \
	-v /chain/config.json:/home/Service/test/config.json \
	--network=host \
	--name fabric-sdk registry.cn-hangzhou.aliyuncs.com/wangyi0559/eval:latest 
}
startSDK >/dev/null 2>&1
echo "success"