#!/bin/bash
# Copyright London Stock Exchange Group All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
echo
echo " ____    _____      _      ____    _____           _____   ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|         | ____| |___ \  | ____|"
echo "\___ \    | |     / _ \   | |_) |   | |    _____  |  _|     __) | |  _|  "
echo " ___) |   | |    / ___ \  |  _ <    | |   |_____| | |___   / __/  | |___ "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|           |_____| |_____| |_____|"
echo

opMODE=$1

CHANNEL_NAME=poachannel
CHANNEL_NAME_2=porchannel

TIMEOUT=60
COUNTER=1
MAX_RETRY=5
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/rufcb.com/orderers/main.rufcb.com/msp/tlscacerts/tlsca.rufcb.com-cert.pem

echo "opMODE : "$opMODE
echo "Channel name : "$CHANNEL_NAME 
echo "Channel name : "$CHANNEL_NAME_2 

info() {
    #figlet $1
    echo "**************************************************************************************"
    echo "$1"
    echo "**************************************************************************************"
    sleep 2
}

verifyResult () {
	if [ $1 -ne 0 ] ; then
		echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
                echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
		echo
   		exit 1
	fi
}

setGlobals () {

	if [ $1 -eq 0 -o $1 -eq 1 ] ; then
		CORE_PEER_LOCALMSPID="Org1MSP"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.rufcb.com/peers/node1.org1.rufcb.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.rufcb.com/users/Admin@org1.rufcb.com/msp
		if [ $1 -eq 0 ]; then
			CORE_PEER_ADDRESS=node1.org1.rufcb.com:7151
		else
			CORE_PEER_ADDRESS=node2.org1.rufcb.com:7151
		fi
	else
		CORE_PEER_LOCALMSPID="Org2MSP"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.rufcb.com/peers/node3.org2.rufcb.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.rufcb.com/users/Admin@org2.rufcb.com/msp
		if [ $1 -eq 2 ]; then
			CORE_PEER_ADDRESS=node3.org2.rufcb.com:7151
		else
			CORE_PEER_ADDRESS=node4.org2.rufcb.com:7151
		fi
	fi

	env |grep CORE
}

createChannel() {
	setGlobals 0

        if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer channel create -o main.rufcb.com:7150 -c $CHANNEL_NAME -f ./channel-artifacts/poachannel.tx >&log.txt
	else
		peer channel create -o main.rufcb.com:7150 -c $CHANNEL_NAME -f ./channel-artifacts/poachannel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel \"$CHANNEL_NAME\" is created successfully ===================== "
	echo
}

updateAnchorPeers() {
        PEER=$1
        setGlobals $PEER

        if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer channel update -o main.rufcb.com:7150 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchorsPoa.tx >&log.txt
	else
		peer channel update -o main.rufcb.com:7150 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchorsPoa.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Anchor peer update failed"
	echo "===================== Anchor peers for org \"$CORE_PEER_LOCALMSPID\" on \"$CHANNEL_NAME\" is updated successfully ===================== "
	sleep 5
	echo
}

## Sometimes Join takes time hence RETRY atleast for 5 times
joinWithRetry () {
	peer channel join -b $CHANNEL_NAME.block  >&log.txt
	res=$?
	cat log.txt
	if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo "PEER$1 failed to join the channel, Retry after 2 seconds"
		sleep 2
		joinWithRetry $1
	else
		COUNTER=1
	fi
        verifyResult $res "After $MAX_RETRY attempts, PEER$ch has failed to Join the Channel"
}

joinChannel () {
	for ch in 0 1 2 3; do
		setGlobals $ch
		joinWithRetry $ch
		echo "===================== PEER$ch joined on the channel \"$CHANNEL_NAME\" ===================== "
		sleep 2
		echo
	done
}

installChaincode () {
	PEER=$1
	setGlobals $PEER
	peer chaincode install -n mycc -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02 >&log.txt
	res=$?
	cat log.txt
        verifyResult $res "Chaincode installation on remote peer PEER$PEER has Failed"
	echo "===================== Chaincode is installed on remote peer PEER$PEER ===================== "
	echo
}

instantiateChaincode () {
	PEER=$1
	setGlobals $PEER
	# while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
	# lets supply it directly as we know it using the "-o" option
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode instantiate -o main.rufcb.com:7150 -C $CHANNEL_NAME -n mycc -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "OR	('Org1MSP.member','Org2MSP.member')" >&log.txt
	else
		peer chaincode instantiate -o main.rufcb.com:7150 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mycc -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "OR	('Org1MSP.member','Org2MSP.member')" >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Chaincode instantiation on PEER$PEER on channel '$CHANNEL_NAME' failed"
	echo "===================== Chaincode Instantiation on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}

instantiateChaincodeX () {
	PEER=$1
    N=$2
    I=$3
    CHAN=$4
	setGlobals $PEER
	# while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
	# lets supply it directly as we know it using the "-o" option
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode instantiate -o main.rufcb.com:7150 -C $CHAN -n $N -v 1.0 -c '$I' -P "OR	('Org1MSP.member','Org2MSP.member')" >&log.txt
	else
		peer chaincode instantiate -o main.rufcb.com:7150 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHAN -n $N -v 1.0 -c '$I' -P "OR	('Org1MSP.member','Org2MSP.member')" >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Chaincode instantiation on node$PEER on channel '$CHANNEL_NAME' failed"
	echo "===================== Chaincode Instantiation on node$PEER on channel '$CHAN' is successful ===================== "
	echo

}


chaincodeQuery () {
  PEER=$1
  echo "===================== Querying on PEER$PEER on channel '$CHANNEL_NAME'... ===================== "
  setGlobals $PEER
  local rc=1
  local starttime=$(date +%s)

  # continue to poll
  # we either get a successful response, or reach TIMEOUT
  while test "$(($(date +%s)-starttime))" -lt "$TIMEOUT" -a $rc -ne 0
  do
     sleep 3
     echo "Attempting to Query PEER$PEER ...$(($(date +%s)-starttime)) secs"
     peer chaincode query -C $CHANNEL_NAME -n mycc -c '{"Args":["query","a"]}' >&log.txt
     test $? -eq 0 && VALUE=$(cat log.txt | awk '/Query Result/ {print $NF}')
     test "$VALUE" = "$2" && let rc=0
  done
  echo
  cat log.txt
  if test $rc -eq 0 ; then
	echo "===================== Query on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
  else
	echo "!!!!!!!!!!!!!!! Query result on PEER$PEER is INVALID !!!!!!!!!!!!!!!!"
        echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
	echo
	exit 1
  fi
}

chaincodeInvoke () {
	PEER=$1
	setGlobals $PEER
	# while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
	# lets supply it directly as we know it using the "-o" option
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o main.rufcb.com:7150 -C $CHANNEL_NAME -n mycc -c '{"Args":["invoke","a","b","10"]}' >&log.txt
	else
		peer chaincode invoke -o main.rufcb.com:7150  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mycc -c '{"Args":["invoke","a","b","10"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke execution on PEER$PEER failed "
	echo "===================== Invoke transaction on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}

createChannel2() {
	setGlobals 0

        if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer channel create -o main.rufcb.com:7150 -c porchannel -f ./channel-artifacts/porchannel.tx >&log.txt
	else
		peer channel create -o main.rufcb.com:7150 -c porchannel -f ./channel-artifacts/porchannel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Channel2 creation failed"
	echo "===================== Channel2 \"porchannel\" is created successfully ===================== "
	echo
}

## Sometimes Join takes time hence RETRY atleast for 5 times
joinWithRetry2 () {
	peer channel join -b porchannel.block  >&log.txt
	res=$?
	cat log.txt
	if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo "PEER$1 failed to join the channel, Retry after 2 seconds"
		sleep 2
		joinWithRetry2 $1
	else
		COUNTER=1
	fi
        verifyResult $res "After $MAX_RETRY attempts, PEER$ch has failed to Join the Channel2"
}

joinChannel2 () {
	for ch in 0 1 2 3; do
		setGlobals $ch
		joinWithRetry2 $ch
		echo "===================== PEER$ch joined on the channel2 \"porchannel\" ===================== "
		sleep 2
		echo
	done
}

updateAnchorPeers2() {
        PEER=$1
        setGlobals $PEER

        if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer channel update -o main.rufcb.com:7150 -c porchannel -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchorsPor.tx >&log.txt
	else
		peer channel update -o main.rufcb.com:7150 -c porchannel -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchorsPor.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Anchor peer update failed porchannel"
	echo "===================== Anchor peers for org \"$CORE_PEER_LOCALMSPID\" on \"porchannel\" is updated successfully ===================== "
	sleep 5
	echo
}

instantiateChaincode2 () {
	PEER=$1
	setGlobals $PEER
	# while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
	# lets supply it directly as we know it using the "-o" option
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode instantiate -o main.rufcb.com:7150 -C porchannel -n mycc -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "OR	('Org1MSP.member','Org2MSP.member')" >&log.txt
	else
		peer chaincode instantiate -o main.rufcb.com:7150 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C porchannel -n mycc -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "OR	('Org1MSP.member','Org2MSP.member')" >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Chaincode instantiation on PEER$PEER on channel 'porchannel' failed"
	echo "===================== Chaincode Instantiation on PEER$PEER on channel 'porchannel' is successful ===================== "
	echo
}

chaincodeQuery2 () {
  PEER=$1
  echo "===================== Querying on PEER$PEER on channel 'porchannel'... ===================== "
  setGlobals $PEER
  local rc=1
  local starttime=$(date +%s)

  # continue to poll
  # we either get a successful response, or reach TIMEOUT
  while test "$(($(date +%s)-starttime))" -lt "$TIMEOUT" -a $rc -ne 0
  do
     sleep 3
     echo "Attempting to Query PEER$PEER ...$(($(date +%s)-starttime)) secs"
     peer chaincode query -C porchannel -n mycc -c '{"Args":["query","a"]}' >&log.txt
     test $? -eq 0 && VALUE=$(cat log.txt | awk '/Query Result/ {print $NF}')
     test "$VALUE" = "$2" && let rc=0
  done
  echo
  cat log.txt
  if test $rc -eq 0 ; then
	echo "===================== Query on PEER$PEER on channel 'porchannel' is successful ===================== "
  else
	echo "!!!!!!!!!!!!!!! Query result on PEER$PEER is INVALID !!!!!!!!!!!!!!!!"
        echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
	echo
	exit 1
  fi
}

chaincodeInvoke2 () {
	PEER=$1
	setGlobals $PEER
	# while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
	# lets supply it directly as we know it using the "-o" option
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o main.rufcb.com:7150 -C porchannel -n mycc -c '{"Args":["invoke","a","b","10"]}' >&log.txt
	else
		peer chaincode invoke -o main.rufcb.com:7150  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C porchannel -n mycc -c '{"Args":["invoke","a","b","10"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke execution on PEER$PEER failed "
	echo "===================== Invoke transaction on PEER$PEER on channel 'porchannel' is successful ===================== "
	echo
}

installChaincodeX() {
	PEER=$1
    N=$2
    P=$3
	setGlobals $PEER
	peer chaincode install -n $N -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/$P >&log.txt
	res=$?
	cat log.txt
        verifyResult $res "Chaincode installation on remote peer node$PEER has Failed"
	echo "===================== Chaincode is installed on remote peer node$PEER ===================== "
	echo
}

installChaincodeXV() {
	PEER=$1
    N=$2
    P=$3
   VV=$4 
	setGlobals $PEER
	peer chaincode install -n $N -v $VV -p github.com/hyperledger/fabric/examples/chaincode/go/$P >&log.txt
	res=$?
	cat log.txt
        verifyResult $res "Chaincode installation on remote peer node$PEER has Failed"
	echo "===================== Chaincode is installed on remote peer node$PEER ===================== "
	echo
}


instantiateChaincodeX () {
	PEER=$1
    N=$2
    I=$3
    CHAN=$4
	setGlobals $PEER
	# while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
	# lets supply it directly as we know it using the "-o" option
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode instantiate -o main.rufcb.com:7150 -C $CHAN -n $N -v 1.0 -c $I -P "OR	('Org1MSP.member','Org2MSP.member')" >&log.txt
	else
		peer chaincode instantiate -o main.rufcb.com:7150 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHAN -n $N -v 1.0 -c $I -P "OR	('Org1MSP.member','Org2MSP.member')" >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Chaincode instantiation on node$PEER on channel '$CHANNEL_NAME' failed"
	echo "===================== Chaincode Instantiation on node$PEER on channel '$CHAN' is successful ===================== "
	echo

}

upgradeChaincodeXV () {
	PEER=$1
    N=$2
    I=$3
    CHAN=$4
    VV=$5
	setGlobals $PEER
	# while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
	# lets supply it directly as we know it using the "-o" option
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode upgrade -o main.rufcb.com:7150 -C $CHAN -n $N -v $VV -c $I -P "OR	('Org1MSP.member','Org2MSP.member')" >&log.txt
	else
		peer chaincode upgrade -o main.rufcb.com:7150 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHAN -n $N -v $VV -c $I -P "OR	('Org1MSP.member','Org2MSP.member')" >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Chaincode instantiation on node$PEER on channel '$CHANNEL_NAME' failed"
	echo "===================== Chaincode Instantiation on node$PEER on channel '$CHAN' is successful ===================== "
	echo
}


if [ "${opMODE}" == "installPoaCC" ]; then
  installChaincodeX 0 poachaincode poachaincode
  installChaincodeX 1 poachaincode poachaincode
  installChaincodeX 2 poachaincode poachaincode
  installChaincodeX 3 poachaincode poachaincode
elif [ "${opMODE}" == "installPoaCCV" ]; then
  echo " installPoaCCV : poachaincode : Path $2 : ver $3 "
  installChaincodeXV 0 poachaincode $2 $3
  installChaincodeXV 1 poachaincode $2 $3
  installChaincodeXV 2 poachaincode $2 $3
  installChaincodeXV 3 poachaincode $2 $3
elif [ "${opMODE}" == "installPorCC" ]; then
  installChaincodeX 0 porchaincode porchaincode
  installChaincodeX 1 porchaincode porchaincode
  installChaincodeX 2 porchaincode porchaincode
  installChaincodeX 3 porchaincode porchaincode
elif [ "${opMODE}" == "installPorCCV" ]; then
  echo " installPorCCV : porchaincode : Path $2 : ver $3 "
  installChaincodeXV 0 porchaincode $2 $3
  installChaincodeXV 1 porchaincode $2 $3
  installChaincodeXV 2 porchaincode $2 $3
  installChaincodeXV 3 porchaincode $2 $3
elif [ "${opMODE}" == "instantiatePoaCC" ]; then
  instantiateChaincodeX 0 poachaincode '{"Args":["init","P9u3B1uXuku76fsFdSQ9DnHTb4CX3KkDws","PK9kq3cxihCXnT8roTTXbYe3eNwYwxEJLD"]}' $CHANNEL_NAME
elif [ "${opMODE}" == "upgradePoaCCV" ]; then
  echo " upgradePoaCCV : poachaincode : ver $2 "
  upgradeChaincodeXV 0 poachaincode '{"Args":["init","P9u3B1uXuku76fsFdSQ9DnHTb4CX3KkDws","PK9kq3cxihCXnT8roTTXbYe3eNwYwxEJLD"]}' $CHANNEL_NAME $2
elif [ "${opMODE}" == "instantiatePorCC" ]; then
  instantiateChaincodeX 0 porchaincode '{"Args":["init","RE7QBqhXoZCjKPxpAheLyShTcjco22Jhbp"]}' $CHANNEL_NAME_2
elif [ "${opMODE}" == "upgradePorCCV" ]; then
  echo " upgradePorCCV : porchaincode : ver $2 "
  upgradeChaincodeXV 0 porchaincode '{"Args":["init","RE7QBqhXoZCjKPxpAheLyShTcjco22Jhbp"]}' $CHANNEL_NAME_2 $2
else
  exit 1
fi



echo
echo " _____   _   _   ____            _____   ____    _____ "
echo "| ____| | \ | | |  _ \          | ____| |___ \  | ____|"
echo "|  _|   |  \| | | | | |  _____  |  _|     __) | |  _|  "
echo "| |___  | |\  | | |_| | |_____| | |___   / __/  | |___ "
echo "|_____| |_| \_| |____/          |_____| |_____| |_____|"
echo

exit 0
