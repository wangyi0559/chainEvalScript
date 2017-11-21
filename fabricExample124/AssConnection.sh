#!/bin/bash
# author:wang yi

function AssConnection(){
    docker network connect artifacts_default `cat /chain/CONTAINER_NAME` 
}
AssConnection > /dev/null 2>&1
echo "success"