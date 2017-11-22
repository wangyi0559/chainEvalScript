#!/bin/bash
# author:wang yi
export VERSION=1.0.0

export ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')

curl https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric/${ARCH}-${VERSION}/hyperledger-fabric-${ARCH}-${VERSION}.tar.gz | tar xz

cd bin

./cryptogen generate --config=./cryptogen.yaml

export FABRIC_CFG_PATH=$PWD
./configtxgen -profile TwoOrgsOrdererGenesis -outputBlock ./genesis.block

export CHANNEL_NAME=mychannel
./configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./mychannel.tx -channelID $CHANNEL_NAME