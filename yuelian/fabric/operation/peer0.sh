#!/bin/bash
# author:wang yi

opMODE=$1

CHANNEL_NAME=poachannel
CHANNEL_NAME_2=porchannel

TIMEOUT=60
COUNTER=1
MAX_RETRY=5

ORDERER_CA=/home/user/ouyeel/ouyeelSdk/artifacts/channel/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

setGlobals () {

	if [ $1 -eq 0 -o $1 -eq 1 ] ; then
		CORE_PEER_LOCALMSPID="Org1MSP"
		CORE_PEER_TLS_ROOTCERT_FILE=/home/user/ouyeel/ouyeelSdk/artifacts/channel/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/home/user/ouyeel/ouyeelSdk/artifacts/channel/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp
		if [ $1 -eq 0 ]; then
			CORE_PEER_ADDRESS=peer0.org1.example.com:7051
		else
			CORE_PEER_ADDRESS=peer1.org1.example.com:7051
		fi
	else
		CORE_PEER_LOCALMSPID="Org2MSP"
		CORE_PEER_TLS_ROOTCERT_FILE=/home/user/ouyeel/ouyeelSdk/artifacts/channel/crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/home/user/ouyeel/ouyeelSdk/artifacts/channel/crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/msp
		if [ $1 -eq 2 ]; then
			CORE_PEER_ADDRESS=peer0.org2.example.com:7051
		else
			CORE_PEER_ADDRESS=peer1.org2.example.com:7051
		fi
	fi

	env |grep CORE
}
createChannel() {
	setGlobals 0

    if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer channel create -o main.example.com:7050 -c $CHANNEL_NAME -f /home/user/ouyeel/ouyeelSdk/artifacts/channel/mychannel.tx >log.txt 2>&1
	else
		peer channel create -o main.example.com:7050 -c $CHANNEL_NAME -f /home/user/ouyeel/ouyeelSdk/artifacts/channel/mychannel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >log.txt 2>&1
	fi
	cat log.txt
}
