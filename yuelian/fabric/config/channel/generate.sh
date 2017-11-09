#!/bin/bash
# author:wang yi

./cryptogen generate --config=./cryptogen.yaml

export FABRIC_CFG_PATH=$PWD
./configtxgen -profile TwoOrgsOrdererGenesis -outputBlock ./genesis.block

export CHANNEL_NAME=mychannel
./configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./mychannel.tx -channelID $CHANNEL_NAME