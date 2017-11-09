#!/bin/sh	
# author:wang yi
function instantiateChaincode(){
    docker run --rm --privileged=true \
    --network=host \
    -d registry.cn-hangzhou.aliyuncs.com/wangyi0559/eval-init curl 127.0.0.1:8080/api/instantiateChaincode >/dev/null 2>&1
}
PEER_INDEX=$(cat /chain/PEER_INDEX)
function initFabric(){
    case $PEER_INDEX in
        4)  {
            /bin/bash /chain/chainEvalScript/fabricExample124/init/init-p0o1.sh >/dev/null 2>&1
            sleep 65s
            instantiateChaincode
            sleep 10s
        }
        ;;
        5)  {
            sleep 50s
            /bin/bash /chain/chainEvalScript/fabricExample124/init/init-p1o1.sh >/dev/null 2>&1
            sleep 80s
            instantiateChaincode
            sleep 10s
        }
        ;;
        6)  {
            sleep 30s
            /bin/bash /chain/chainEvalScript/fabricExample124/init/init-p0o2.sh >/dev/null 2>&1
            sleep 70s
            instantiateChaincode
            sleep 10s
        }
        ;;
        7)  {
            sleep 60s
            /bin/bash /chain/chainEvalScript/fabricExample124/init/init-p1o2.sh >/dev/null 2>&1
            sleep 75s
            instantiateChaincode
            sleep 10s
        }
        ;;
        *)  echo 'error' >/dev/null 2>&1
        ;;
    esac
}
sleep 2s
initFabric