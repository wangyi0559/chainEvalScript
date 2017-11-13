#!/bin/sh	
# author:wang yi
NUM1MINUTE=$*
a=$(( $NUM1MINUTE / 10 ))
b=$(( $NUM1MINUTE % 10 ))
for((i=1;i<=$a;i++));
do
nohup curl -s -X GET 127.0.0.1:8080/api/invokeCC?num=10 >/dev/null 2>&1 &
sleep 1s
done
if [ $b != "0" ]
then
nohup curl -s -X GET 127.0.0.1:8080/api/invokeCC?num=$b >/dev/null 2>&1 &
fi
echo "success"