#!/bin/sh	
# author:wang yi

PEER_INDEX=$(cat /chain/PEER_INDEX)
function initFabric(){
    case $PEER_INDEX in
        3)  {
            /bin/bash /chain/chainEvalScript/fabricExample1120/init/init-p0o1.sh >/dev/null 2>&1
        }
        ;;
        4|5|6|7|8|9|10|11|12|13|14|15|16|17|18|19|20|21|22)  {
            sleep 60s
            sleep $PEER_INDEX 
            /bin/bash /chain/chainEvalScript/fabricExample1120/init/init-p1o1.sh >/dev/null 2>&1
        }
        ;;
        *)  echo 'error' >/dev/null 2>&1
        ;;
    esac
}
sleep 2s
initFabric