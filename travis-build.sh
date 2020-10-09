#!/bin/bash
# Set these environment variables
#DOCKER_USER=
#DOCKER_AUTH=

set -e

ORG=${ORG:-hsldevcom}
DOCKER_TAG="latest"
DOCKER_IMAGE=$ORG/pelias-api
API=pelias-api

if [ "$TRAVIS_TAG" ]; then
  DOCKER_TAG="prod"
elif [ "$TRAVIS_BRANCH" != "master" ]; then
  DOCKER_TAG=$TRAVIS_BRANCH
fi

DOCKER_TAG_LONG=$DOCKER_TAG-$(date +"%Y-%m-%dT%H.%M.%S")-${TRAVIS_COMMIT:0:7}
DOCKER_IMAGE_LATEST=$DOCKER_IMAGE:latest
DOCKER_IMAGE_TAG=$DOCKER_IMAGE:$DOCKER_TAG
DOCKER_IMAGE_TAG_LONG=$DOCKER_IMAGE:$DOCKER_TAG_LONG


if [ -z $TRAVIS_TAG ]; then
    # Build image
    echo "Building pelias-api"
    docker build --tag="$DOCKER_IMAGE_TAG_LONG" .
    docker run --name $API -p 3100:8080 --rm $DOCKER_IMAGE_TAG_LONG &
    sleep 20
    HOST=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' $API)
    STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$HOST:8080/v1)
    docker stop $API

    if [ $STATUS_CODE = 200 ]; then
        echo "Image runs OK"
    else
        echo "Could not launch pelias api image"
        # exit with an error
        exit 1
    fi
fi

if [ "${TRAVIS_PULL_REQUEST}" == "false" ]; then
    docker login -u $DOCKER_USER -p $DOCKER_AUTH
    if [ "$TRAVIS_TAG" ];then
      echo "processing release $TRAVIS_TAG"
      docker pull $DOCKER_IMAGE_LATEST
      docker tag $DOCKER_IMAGE_LATEST $DOCKER_IMAGE_TAG
      docker tag $DOCKER_IMAGE_LATEST $DOCKER_IMAGE_TAG_LONG
      docker push $DOCKER_IMAGE_TAG
      docker push $DOCKER_IMAGE_TAG_LONG
    else
      echo "Pushing $DOCKER_TAG image"
      docker push $DOCKER_IMAGE_TAG_LONG
      docker tag $DOCKER_IMAGE_TAG_LONG $DOCKER_IMAGE_TAG
      docker push $DOCKER_IMAGE_TAG
    fi
fi


echo Build completed
