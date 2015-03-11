#!/bin/bash
set -e

D=`cf apps | grep photo-service | tr -s ' ' | cut -d' ' -f 6 | cut -d, -f1`
echo $D

curl -o $1.jpg http://$D/$1/photo
