#!/bin/bash
set -e

D=`cf apps | grep photo-service | tr -s ' ' | cut -d' ' -f 6 | cut -d, -f1`
echo $D

echo $1

curl -XPOST -v http://$D/$1/photo -F "multipartFile=@$2"
