#!/bin/bash
# author:wang yi

STATUS=$(cat /status)
if [ $STATUS == "1" ]
then
    /bin/bash /chain/chainEvalScript/yuelian/fabric/fabric_init.sh >/dev/null 2>&1
    echo 2 > /status
    echo "success"
else
    echo "error"
fi