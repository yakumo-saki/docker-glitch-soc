# Mastodon Glitch Edition Dockerfile and docker-compose

## why ?

* official dockerfile needs much time to build. (Compiling ruby took long time)
* Using ruby official image to faster build.

## known issue

* ~Ruby not using jmalloc~
* node.js version must be changed when node.js LTS is updated

## pre-built image 

* https://hub.docker.com/r/yakumosaki/glitch-soc
