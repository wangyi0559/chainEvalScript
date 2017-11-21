#!/bin/bash
# author:wang yi
function disConnection(){
    docker network disconnect artifacts_default `cat /chain/CONTAINER_NAME` 
}
disConnection > /dev/null 2>&1
echo "success"