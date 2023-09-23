[![Build x86 GHA](https://github.com/yakumo-saki/docker-glitch-soc/actions/workflows/image-build.yml/badge.svg)](https://github.com/yakumo-saki/docker-glitch-soc/actions/workflows/image-build.yml) Build x86 GitHub Action  
![AArch64 CircleCI](https://circleci.com/gh/yakumo-saki/docker-glitch-soc.svg?style=shield) Build AArch64 CircleCI  


# Mastodon Glitch Edition Dockerfile and docker-compose

Mastodon glitch edition official image is available:  
https://github.com/glitch-soc/mastodon/pkgs/container/mastodon

My build:

* yakumosaki/glitch-soc-aarch64
* yakumosaki/glitch-soc

## news

Date is in JST (GMT+9)

* 2023/09/23 build is back to normal. docker image is now based on bookworm (debian 12).
* 2023/09/20 build is failling x86_64 and aarch64 images.
* 2023/04/06 replace Dockerfile with glitch-soc's. This improve stability on my environment. And also container image size become 1/2 (1GB -> 550MB)
* 2023/04/03 build is failling. Checking for reason. and has (issue)[https://github.com/yakumo-saki/docker-glitch-soc/issues/7] ?
* 2022/07/06 x86_64 docker image build is back to normal.
* 2022/06/11 aarch64 docker image build is started. (thanks to Oracle Cloud Free tier)
* 2022/04/22 docker image build has been stopped for two months because of my internet access loss.

## why ?

* official dockerfile needs much time to build. (Compiling ruby took long time)
* Using ruby official image to faster build.

## known issue

* ~Ruby not using jmalloc~
* node.js version must be changed when node.js LTS is updated

## pre-built image 

* https://hub.docker.com/r/yakumosaki/glitch-soc  (x86_64)
* https://hub.docker.com/r/yakumosaki/glitch-soc-aarch64 8arch64)
