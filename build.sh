#!/bin/bash -eu

# local docker image tag

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


# BUILD
cd $WORK
echo "building docker image ${DOCKERHUB_IMAGENAME}:${DOCKER_TAG} on `pwd`"


# PUSH
docker push $DOCKERHUB_IMAGENAME:$DOCKER_TAG
docker push $DOCKERHUB_IMAGENAME:latest
