#!/bin/bash -eu

# =====================================================================
# config
# =====================================================================

BASE_DIR=$(cd $(dirname $0); pwd)
DOCKERFILE="$BASE_DIR/Dockerfile"
MASTODON_DIR="$BASE_DIR/mastodon"

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
  echo "git clone https://github.com/glitch-soc/mastodon.git mastodon"
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

echo ""
echo "### PREPARE SUCCESS ###"
echo "You must docker build to build new image"
