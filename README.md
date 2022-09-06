[![Build glitch-soc docker Image](https://github.com/yakumo-saki/docker-glitch-soc/actions/workflows/image-build.yml/badge.svg)](https://github.com/yakumo-saki/docker-glitch-soc/actions/workflows/image-build.yml)

# Mastodon Glitch Edition Dockerfile and docker-compose

## news

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
