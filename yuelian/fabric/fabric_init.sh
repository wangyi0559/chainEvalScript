#!/bin/sh	
# author:wang yi
PEER_INDEX=$(cat /chain/PEER_INDEX)
function initFabric(){
    case $PEER_INDEX in
        3)  {
            curl 127.0.0.1:8080/api/users
            sleep 5s
            curl 127.0.0.1:8080/api/createChannel 
            sleep 5s 
            curl 127.0.0.1:8080/api/joinchannel 
            sleep 10s
        }
        ;;
        4|5)  {
            sleep 30s
            sleep $PEER_INDEX
            curl 127.0.0.1:8080/api/users
            sleep 10s
        }
        ;;
        6)  {
            sleep 40s
            sleep $PEER_INDEX
            curl 127.0.0.1:8080/api/users
            sleep 5s
            curl 127.0.0.1:8080/api/installChaincode 
            sleep 10s
            curl 127.0.0.1:8080/api/instantiateChaincode 
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