#!/bin/sh	
# author:wang yi
NUM1MINUTE=$*
curl -s -X GET --connect-timeout 3000 -m 3000 127.0.0.1:8080/api/invokeCC?num=$NUM1MINUTE