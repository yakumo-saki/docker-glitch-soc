#!/bin/bash -eu

# =====================================================================
# config
# =====================================================================

BASE_DIR=$(cd $(dirname $0); pwd)
DOCKERFILE="$BASE_DIR/Dockerfile"
MASTODON_DIR="$BASE_DIR/build"

# local docker image tag
DOCKER_TAG=`date '+%Y%m%d_%H'`
DOCKERHUB_IMAGENAME="yakumosaki/glitch-soc"

# x86_64 / aarch64
ARCH=`uname -m`

# =====================================================================
# functions
# =====================================================================

function git_banner() {
    echo "***********************************************************"
    echo "git commit is "
    echo " "
    echo $1
    echo " "
    echo "***********************************************************"
}

function process_banner() {
    echo "---------------------"
    echo $1
    echo "---------------------"
}

function small_banner() {
    echo "*** $1 ***"
}

# =====================================================================
# begin procedure
# =====================================================================

# is mastodon cloned ? 
if [ ! -d $MASTODON_DIR ];then
  echo "FATAL: 'build' directory not found."
  echo "Please run command below on ${BASE_DIR}"
  echo "git clone https://github.com/glitch-soc/mastodon.git build"
  exit 16
fi

# get mastodon commit hash.
cd $MASTODON_DIR
git reset --hard > /dev/null
GIT_COMMIT=`git rev-parse --short HEAD`

git_banner $GIT_COMMIT

# version string shown in Mastodon UI, etc.
DISP_VER="`date '+%m%d'_${GIT_COMMIT:0:7}`"

##
process_banner "patch"
##

small_banner "edit TAG.rb to change version string"
VERSION_RB=${MASTODON_DIR}/lib/mastodon/version.rb
echo "add TAG suffix $DISP_VER"
sed -i -e "s/\+glitch/\+glitch_${DISP_VER}/" "${VERSION_RB}"

#small_banner "patch Gemfile.lock"
# echo "gem 'mimemagic', '~> 0.3.10'" >> Gemfile
# sed -i s/mimemagic.*0.3.5/"mimemagic (0.3.10"/ Gemfile.lock

echo "patch done"

##
process_banner "docker build"
##

cd $BASE_DIR
echo "building docker image ${DOCKERHUB_IMAGENAME}:${DOCKER_TAG} on `pwd`"

docker build -t $DOCKERHUB_IMAGENAME:$DOCKER_TAG -f $ARCH/Dockerfile .
docker tag $DOCKERHUB_IMAGENAME:$DOCKER_TAG $DOCKERHUB_IMAGENAME:latest

exit 16

process_banner "tagging and upload"
echo "docker tag is $DOCKERHUB_IMAGENAME:$DOCKER_TAG [latest]"

docker push $DOCKERHUB_IMAGENAME:$DOCKER_TAG
docker push $DOCKERHUB_IMAGENAME:latest

echo "docker push success."

# バージョンつきイメージはローカルには不要なので消しておく
echo ""
echo "*** delete tag $DOCKERHUB_IMAGENAME:$DOCKER_TAG ***"
docker image rm $DOCKERHUB_IMAGENAME:$DOCKER_TAG

#yes | docker image prune

echo ""
echo "### BUILD SUCCESS ###"
