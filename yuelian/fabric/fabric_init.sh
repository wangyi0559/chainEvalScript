#!/bin/sh	
# author:wang yi
function instantiateChaincode(){
    docker run --rm --privileged=true \
    --network=host \
    -d registry.cn-hangzhou.aliyuncs.com/wangyi0559/eval-init curl 127.0.0.1:8080/api/instantiateChaincode 
}
PEER_INDEX=$(cat /chain/PEER_INDEX)
function initFabric(){
    case $PEER_INDEX in
        3)  {
            /bin/bash /chain/chainEvalScript/yuelian/fabric/init/init-p0o1.sh
            sleep 70s
            instantiateChaincode
            sleep 10s 
        }
        ;;
        4|5|6)  {
            sleep 30s
            sleep $PEER_INDEX
            /bin/bash /chain/chainEvalScript/yuelian/fabric/init/init-p1o1.sh
            sleep 70s
            instantiateChaincode
            sleep 10s
        }
        ;;
        *)  echo 'error' 
        ;;
    esac
}
sleep 2s
initFabric >/dev/null 2>&1
echo "success"