#!/bin/bash
set -e


if [ "$1" != "" ]; then
    case $1 in
        -f | --force )    force=1
                          ;;
        * )               force=0
                          ;;
    esac
fi

#
# the big CloudFoundry installer
#

CLOUD_DOMAIN=${DOMAIN:-run.pivotal.io}
CLOUD_TARGET=api.${DOMAIN}

function login(){
  cf api | grep ${CLOUD_TARGET} || cf api ${CLOUD_TARGET} --skip-ssl-validation
  cf a | grep OK || cf login
}

function app_domain(){
  D=`cf apps | grep $1 | tr -s ' ' | cut -d' ' -f 6 | cut -d, -f1`
  echo $D
}

function deploy_app(){
  APP_NAME=$1
  cd $APP_NAME
  cf push $APP_NAME
  cd ..
}

function deploy_service(){
  N=$1
  D=`app_domain $N`
  JSON='{"uri":"http://'$D'"}'
  echo cf cups $N  -p $JSON
  cf cups $N -p $JSON
}

function deploy_eureka() {
  NAME=eureka-service
  deploy_app $NAME
  deploy_service $NAME
}

function deploy_eureka_peer(){
  DIR_NAME=eureka-service
  APP_NAME=eureka-peer-service
  cd $DIR_NAME
  cf push $APP_NAME
  cd ..
}

function deploy_photo_service(){
  cf cs mongolab sandbox photo-service-mongodb
  deploy_app photo-service
}

function deploy_bookmark_service(){
  cf cs elephantsql turtle bookmark-service-postgresql
  deploy_app bookmark-service
}

function deploy_passport_service(){
  deploy_app passport-service
}

function reset(){
  cf d eureka-service
  cf d eureka-peer-service
  cf d photo-service
  cf d passport-service
  cf d bookmark-service
  cf ds photo-service-mongodb
  cf ds bookmark-service-postgresql
  cf ds eureka-service
  cf delete-orphaned-routes
}

function force_reset(){
  cf d -f -r eureka-service
  cf d -f -r eureka-peer-service
  cf d -f -r photo-service
  cf d -f -r passport-service
  cf d -f -r bookmark-service
  cf ds -f photo-service-mongodb
  cf ds -f bookmark-service-postgresql
  cf ds -f eureka-service
}

mvn -DskipTests=true clean install

login
if [[ $force -eq 1 ]]; then
    echo "Non Interactive Force Resetting of all apps"
    force_reset
else
    reset
fi
deploy_eureka
deploy_eureka_peer
deploy_photo_service
deploy_bookmark_service
deploy_passport_service
