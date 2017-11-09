#!/bin/sh	
# author:wang yi
PEER_INDEX=$1
IP_ORDERER=$2
IP_CA1=$3
IP_CA2=$4
IP_P0O1=$5
IP_P1O1=$6
IP_P0O2=$7
IP_P1O2=$8
echo $PEER_INDEX > /chain/PEER_INDEX
echo $IP_ORDERER > /chain/IP_ORDERER
echo $IP_CA1 > /chain/IP_CA1
echo $IP_CA2 > /chain/IP_CA2
echo $IP_P0O1 > /chain/IP_P0O1
echo $IP_P1O1 > /chain/IP_P1O1
echo $IP_P0O2 > /chain/IP_P0O2
echo $IP_P1O2 > /chain/IP_P1O2

function chooseScript(){
    case $PEER_INDEX in
        1)  {
            sleep 1s
            /bin/bash /chain/chainEvalScript/fabricExample124/start/fabric_orderer_start.sh >/dev/null 2>&1
        }
        ;;
        2)  {
            sleep 3s
            /bin/bash /chain/chainEvalScript/fabricExample124/start/fabric_ca1_start.sh >/dev/null 2>&1
        }
        ;;
        3)  {
            sleep 5s
            /bin/bash /chain/chainEvalScript/fabricExample124/start/fabric_ca2_start.sh >/dev/null 2>&1
        }
        ;;
        4)  {
            sleep 2s
            sed -i "s/THISUSER/Test1/g" /chain/config.json
            sed -i "s/THISORG/org1/g" /chain/config.json
            sed -i "s/PEERSIP1/$IP_P0O1/g" /chain/config.json
            sed -i "s/PEERSIP2/$IP_P1O1/g" /chain/config.json
            sed -i "s/THISPEER/peer1/g" /chain/config.json
            sleep 3s
            /bin/bash /chain/chainEvalScript/fabricExample124/start/fabric_p0o1_start.sh >/dev/null 2>&1
        }
        ;;
        5)  {
            sleep 3s
            sed -i "s/THISUSER/Test2/g" /chain/config.json
            sed -i "s/THISORG/org1/g" /chain/config.json
            sed -i "s/PEERSIP1/$IP_P0O1/g" /chain/config.json
            sed -i "s/PEERSIP2/$IP_P1O1/g" /chain/config.json
            sed -i "s/THISPEER/peer2/g" /chain/config.json
            sleep 3s
            /bin/bash /chain/chainEvalScript/fabricExample124/start/fabric_p1o1_start.sh >/dev/null 2>&1
        }
        ;;
        6)  {
            sleep 4s
            sed -i "s/THISUSER/Test1/g" /chain/config.json
            sed -i "s/THISORG/org2/g" /chain/config.json
            sed -i "s/PEERSIP1/$IP_P0O2/g" /chain/config.json
            sed -i "s/PEERSIP2/$IP_P1O2/g" /chain/config.json
            sed -i "s/THISPEER/peer1/g" /chain/config.json
            sleep 3s
            /bin/bash /chain/chainEvalScript/fabricExample124/start/fabric_p0o2_start.sh >/dev/null 2>&1
        }
        ;;
        7)  {
            sleep 5s      
            sed -i "s/THISUSER/Test2/g" /chain/config.json
            sed -i "s/THISORG/org2/g" /chain/config.json
            sed -i "s/PEERSIP1/$IP_P0O2/g" /chain/config.json
            sed -i "s/PEERSIP2/$IP_P1O2/g" /chain/config.json
            sed -i "s/THISPEER/peer2/g" /chain/config.json
            sleep 3s
            /bin/bash /chain/chainEvalScript/fabricExample124/start/fabric_p1o2_start.sh >/dev/null 2>&1
        }
        ;;
        *)  echo 'error'
        ;;
    esac
}
function configConfigJson(){
    sed -i "s/IP_ORDERER/$IP_ORDERER/g" /chain/config.json
    sed -i "s/IP_CA1/$IP_CA1/g" /chain/config.json
    sed -i "s/IP_CA2/$IP_CA2/g" /chain/config.json
    sed -i "s/IP_P0O1/$IP_P0O1/g" /chain/config.json
    sed -i "s/IP_P1O1/$IP_P1O1/g" /chain/config.json
    sed -i "s/IP_P0O2/$IP_P0O2/g" /chain/config.json
    sed -i "s/IP_P1O2/$IP_P1O2/g" /chain/config.json
}
sleep 2s
configConfigJson
sleep 2s
chooseScript
echo "success"