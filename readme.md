## Introduction
This is a Dockerfile to build a container image for Talaria Web using nginx and php-fpm

## Git repository
The source files for this project can be found here: https://github.com/taladocker/web

## Pulling from Docker Hub
Pull the image from docker hub rather than downloading the git repo. This prevents you having to build the image on every docker host:

```
docker pull tala/web
```

## Running
To simply run the container:

```
docker run --name tala -p 8080:80 -d tala/web
```

You can then browse to http://DOCKER_HOST:8080 to view the default install files.
