#!/bin/bash
# author:wang yi

STATUS=$(cat /status)
if [ $STATUS == "0" ]
then
    /bin/bash /chain/chainEvalScript/yuelian/fabric/fabric_start.sh $* >/dev/null 2>&1
    echo 1 > /status
    echo "success"
else
    echo "error"
fi