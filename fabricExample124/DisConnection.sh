#!/bin/bash
# author:wang yi
PEER_INDEX=$(cat /chain/PEER_INDEX)

function disConnection(){
    case $PEER_INDEX in
        1)   CONTAINER_NAME="orderer.example.com" 
        ;;
        2)   CONTAINER_NAME="ca_peerOrg1" 
        ;;
        3)   CONTAINER_NAME="ca_peerOrg2" 
        ;;
        4)   CONTAINER_NAME="peer0.org1.example.com" 
        ;;
        5)   CONTAINER_NAME="peer1.org1.example.com" 
        ;;
        6)   CONTAINER_NAME="peer0.org2.example.com" 
        ;;
        7)   CONTAINER_NAME="peer1.org2.example.com" 
        ;;
        *)   echo 'error' >/dev/null 2>&1 
        ;;
    esac
    docker network disconnect artifacts_default $CONTAINER_NAME > /dev/null 2>&1
}
disConnection
echo "success"
