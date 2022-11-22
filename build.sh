#!/bin/bash -eu

# local docker image tag
DOCKER_TAG=`date '+%Y%m%d_%H'`
DOCKERHUB_IMAGENAME="yakumosaki/glitch-soc-aarch64"

WORK=.

# PULL
cd ${WORK}
git pull

cd ${WORK}/mastodon
git reset --hard
git pull

${WORK}/prepare.sh $DOCKERHUB_IMAGENAME $DOCKER_TAG

# BUILD
ARCH=`uname -m`
cd $WORK
echo "building docker image ${DOCKERHUB_IMAGENAME}:${DOCKER_TAG} on `pwd`"

docker buildx build -t $DOCKERHUB_IMAGENAME:$DOCKER_TAG -f $ARCH/Dockerfile .
docker tag $DOCKERHUB_IMAGENAME:$DOCKER_TAG $DOCKERHUB_IMAGENAME:latest

# PUSH
docker push $DOCKERHUB_IMAGENAME:$DOCKER_TAG
docker push $DOCKERHUB_IMAGENAME:latest
