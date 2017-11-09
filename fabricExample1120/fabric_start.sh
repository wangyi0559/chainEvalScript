#!/bin/sh	
# author:wang yi
PEER_INDEX=${1}
IP_ORDERER=${2}
IP_CA1=${3}
IP_P0O1=${4}
IP_P1O1=${5}
IP_P2O1=${6}
IP_P3O1=${7}
IP_P4O1=${8}
IP_P5O1=${9}
IP_P6O1=${10}
IP_P7O1=${11}
IP_P8O1=${12}
IP_P9O1=${13}
IP_P10O1=${14}
IP_P11O1=${15}
IP_P12O1=${16}
IP_P13O1=${17}
IP_P14O1=${18}
IP_P15O1=${19}
IP_P16O1=${20}
IP_P17O1=${21}
IP_P18O1=${22}
IP_P19O1=${23}

echo $PEER_INDEX > /chain/PEER_INDEX
echo $IP_ORDERER > /chain/IP_ORDERER
echo $IP_CA1 > /chain/IP_CA1
echo $IP_P0O1 > /chain/IP_P0O1
echo $IP_P1O1 > /chain/IP_P1O1
echo $IP_P2O1 > /chain/IP_P2O1
echo $IP_P3O1 > /chain/IP_P3O1
echo $IP_P4O1 > /chain/IP_P4O1
echo $IP_P5O1 > /chain/IP_P5O1
echo $IP_P6O1 > /chain/IP_P6O1
echo $IP_P7O1 > /chain/IP_P7O1
echo $IP_P8O1 > /chain/IP_P8O1
echo $IP_P9O1 > /chain/IP_P9O1
echo $IP_P10O1 > /chain/IP_P10O1
echo $IP_P11O1 > /chain/IP_P11O1
echo $IP_P12O1 > /chain/IP_P12O1
echo $IP_P13O1 > /chain/IP_P13O1
echo $IP_P14O1 > /chain/IP_P14O1
echo $IP_P15O1 > /chain/IP_P15O1
echo $IP_P16O1 > /chain/IP_P16O1
echo $IP_P17O1 > /chain/IP_P17O1
echo $IP_P18O1 > /chain/IP_P18O1
echo $IP_P19O1 > /chain/IP_P19O1


function chooseScript(){
    case $PEER_INDEX in
        1)  {
            sleep 2s
            /bin/bash /chain/chainEvalScript/fabricExample1120/start/fabric_orderer_start.sh >/dev/null 2>&1
        }
        ;;
        2)  {
            sleep 4s
            /bin/bash /chain/chainEvalScript/fabricExample1120/start/fabric_ca1_start.sh >/dev/null 2>&1
        }
        ;;
        3|4|5|6|7|8|9|10|11|12|13|14|15|16|17|18|19|20|21|22)  {
            sleep 6s
            sleep $PEER_INDEX
            /bin/bash /chain/chainEvalScript/fabricExample1120/start/fabric_peer_start.sh >/dev/null 2>&1
        }
        ;;
        *)  echo 'error'
        ;;
    esac
}
function configConfigJson(){
    sed -i "s/IP_ORDERER/$IP_ORDERER/g" /chain/config.json
    sed -i "s/IP_CA1/$IP_CA1/g" /chain/config.json

    sed -i "s/IP_P0O1/$IP_P0O1/g" /chain/config.json
    sed -i "s/IP_P1O1/$IP_P1O1/g" /chain/config.json
    sed -i "s/IP_P2O1/$IP_P2O1/g" /chain/config.json
    sed -i "s/IP_P3O1/$IP_P3O1/g" /chain/config.json
    sed -i "s/IP_P4O1/$IP_P4O1/g" /chain/config.json
    sed -i "s/IP_P5O1/$IP_P5O1/g" /chain/config.json
    sed -i "s/IP_P6O1/$IP_P6O1/g" /chain/config.json
    sed -i "s/IP_P7O1/$IP_P7O1/g" /chain/config.json
    sed -i "s/IP_P8O1/$IP_P8O1/g" /chain/config.json
    sed -i "s/IP_P9O1/$IP_P9O1/g" /chain/config.json
    sed -i "s/IP_P10O1/$IP_P10O1/g" /chain/config.json
    sed -i "s/IP_P11O1/$IP_P11O1/g" /chain/config.json
    sed -i "s/IP_P12O1/$IP_P12O1/g" /chain/config.json
    sed -i "s/IP_P13O1/$IP_P13O1/g" /chain/config.json
    sed -i "s/IP_P14O1/$IP_P14O1/g" /chain/config.json
    sed -i "s/IP_P15O1/$IP_P15O1/g" /chain/config.json
    sed -i "s/IP_P16O1/$IP_P16O1/g" /chain/config.json
    sed -i "s/IP_P17O1/$IP_P17O1/g" /chain/config.json
    sed -i "s/IP_P18O1/$IP_P18O1/g" /chain/config.json
    sed -i "s/IP_P19O1/$IP_P19O1/g" /chain/config.json
}
sleep 2s
configConfigJson
sleep 2s
chooseScript
echo "success"