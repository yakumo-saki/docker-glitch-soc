#!/bin/bash -eu

# local docker image tag
DOCKER_TAG=`date '+%Y%m%d_%H'`
DOCKERHUB_IMAGENAME="yakumosaki/glitch-soc-aarch64"

GIT_REPO=https://github.com/glitch-soc/mastodon.git

WORK=`pwd`

# PULL
cd ${WORK}
git pull

if [ ! -d "${WORK}/mastodon" ]; then
  git clone --depth=1 https://github.com/glitch-soc/mastodon.git mastodon
fi

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
