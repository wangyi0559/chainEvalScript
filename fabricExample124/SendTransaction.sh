#!/bin/bash
# author:wang yi

STATUS=$(cat /status)
if [ $STATUS == "2" ]
then
    echo 3 > /status
    /bin/bash /chain/chainEvalScript/fabricExample124/fabric_invoke.sh $* >/dev/null 2>&1
    echo 4 > /status
    echo "success"
else
    echo "error"
fi