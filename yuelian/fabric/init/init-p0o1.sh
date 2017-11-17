#!/bin/sh	
# author:wang yi

function checkEvalInit(){
	DOCKER_IMAGE_ID=$(docker images | grep "registry.cn-hangzhou.aliyuncs.com/wangyi0559/eval-init" | awk '{print $3}')
        if [ -z "$DOCKER_IMAGE_ID" -o "$DOCKER_IMAGE_ID" = " " ]; then
		    docker pull registry.cn-hangzhou.aliyuncs.com/wangyi0559/eval-init 
        fi
}
function register(){
    docker run --rm --privileged=true \
    --network=host \
    -d registry.cn-hangzhou.aliyuncs.com/wangyi0559/eval-init curl 127.0.0.1:8080/api/users 
}
function createChannel(){
    docker run --rm --privileged=true \
    --network=host \
    -d registry.cn-hangzhou.aliyuncs.com/wangyi0559/eval-init curl 127.0.0.1:8080/api/createChannel 
}
function joinchannel(){
    docker run --rm --privileged=true \
    --network=host \
    -d registry.cn-hangzhou.aliyuncs.com/wangyi0559/eval-init curl 127.0.0.1:8080/api/joinchannel 
}
#检查镜像是否存在
checkEvalInit >/dev/null 2>&1
#注册SDK，每个节点都需要
register >/dev/null 2>&1
sleep 5s
#创建通道，只需要执行一次
createChannel >/dev/null 2>&1
sleep 5s
#加入通道，每个组织执行一次
joinchannel >/dev/null 2>&1
echo "success"