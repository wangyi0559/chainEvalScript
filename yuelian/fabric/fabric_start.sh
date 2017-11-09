#!/bin/sh	
# author:wang yi
PEER_INDEX=$1
IP_ORDERER=$2
IP_CA1=$3
IP_P0O1=$4
IP_P1O1=$5
IP_P2O1=$6
IP_P3O1=$7
echo $PEER_INDEX > /chain/PEER_INDEX
echo $IP_ORDERER > /chain/IP_ORDERER
echo $IP_CA1 > /chain/IP_CA1
echo $IP_P0O1 > /chain/IP_P0O1
echo $IP_P1O1 > /chain/IP_P1O1
echo $IP_P2O1 > /chain/IP_P2O1
echo $IP_P3O1 > /chain/IP_P3O1
PEER_INDEX1=`expr $PEER_INDEX - 2`
function chooseScript(){
    case $PEER_INDEX in
        1)  {
            sleep 1s
            /bin/bash /chain/chainEvalScript/yuelian/fabric/start/fabric_orderer_start.sh 
        }
        ;;
        2)  {
            sleep 3s
            /bin/bash /chain/chainEvalScript/yuelian/fabric/start/fabric_ca1_start.sh 
        }
        ;;
        3|4|5|6)  {
            sleep 3s
            sleep $PEER_INDEX
            /bin/bash /chain/chainEvalScript/yuelian/fabric/start/fabric_peer_start.sh 
        }
        ;;
        *)  echo 'error'
        ;;
    esac
}
function configConfigJson(){
    sed -i "s/THISUSER/Test$PEER_INDEX1/g" /chain/config.json
    sed -i "s/THISPEER/peer$PEER_INDEX1/g" /chain/config.json
    sed -i "s/IP_ORDERER/$IP_ORDERER/g" /chain/config.json
    sed -i "s/IP_CA1/$IP_CA1/g" /chain/config.json
    sed -i "s/IP_P0O1/$IP_P0O1/g" /chain/config.json
    sed -i "s/IP_P1O1/$IP_P1O1/g" /chain/config.json
    sed -i "s/IP_P2O1/$IP_P2O1/g" /chain/config.json
    sed -i "s/IP_P3O1/$IP_P3O1/g" /chain/config.json
}
sleep 2s
configConfigJson >/dev/null 2>&1
sleep 2s
chooseScript >/dev/null 2>&1
echo "success"