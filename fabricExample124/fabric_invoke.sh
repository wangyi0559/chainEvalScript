#!/bin/sh	
# author:wang yi
NUM1MINUTE=$*
a=$(( $NUM1MINUTE / 10 ))
b=$(( $NUM1MINUTE % 10 ))
for((i=1;i<=$a;i++));
do
curl -s -X GET 127.0.0.1:8080/api/invokeCC?num=10
sleep 5s
done
if [ $b != "0" ]
then
curl -s -X GET 127.0.0.1:8080/api/invokeCC?num=$b
fi
echo "success"