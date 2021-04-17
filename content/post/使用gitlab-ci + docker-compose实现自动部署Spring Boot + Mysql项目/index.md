---
title: "使用gitlab-ci + docker-compose自动部署Spring Boot + Mysql项目"
date: 2021-04-17
description: "日常踩坑"
categories: [
  "开发"
]
tags: [
  "Docker"
]
---

# 部署Runner

使用docker部署runner

- `/srv/gitlab-runner/`保存runner配置

- 挂载`/var/run/docker.sock`便于使用`dind`(docker in docker)

- `/builds`作为持久化挂载锚点：gitlab-ci的docker executor会在每个stage中自动挂载/builds目录（CI过程中的workdir位于/builds的子目录下），将此目录指定映射到宿主机/builds后便可在CI过程中持久化文件。

  dind启动子docker时不能简单挂载相对路径（原因见下文），需要挂载/builds目录间接完成。

- runner反向主动轮询gitlab，一般而言无需映射端口

```shell
docker run -d -v /srv/gitlab-runner/config:/etc/gitlab-runner -v /var/run/docker.sock:/var/run/docker.sock -v /builds:/builds gitlab/gitlab-runner:alpine
```

后续流程参见[官方文档](https://docs.gitlab.com/ee/ci/docker/using_docker_images.html)，exector选择docker，便于项目的打包

# 修改Runner配置

配置文件位于`/srv/gitlab-runner/config/config.toml` ，主要修改`volumes`及`pull_policy`，参考如下

```
concurrent = 1
check_interval = 0

[session_server]
  session_timeout = 1800

[[runners]]
  name = "web"
  url = "https://gitlab.dian.org.cn/"
  token = "rU6aF4pcBSVmSTXN5EXd"
  executor = "docker"
  [runners.custom_build_dir]
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
    [runners.cache.azure]
  [runners.docker]
    tls_verify = false
    image = "maven:3-openjdk-11"
    privileged = false
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/cache", "/var/run/docker.sock:/var/run/docker.sock", "/builds:/builds"]
    shm_size = 0
    pull_policy = "if-not-present"
```

`pull_policy`默认设置为`always`，导致CI过程中每个stage均会重新pull所需的镜像，设置为`if-not-present`告知runner复用已有镜像，加快CI流程

# gitlab-ci配置

### 配置`.gitlab-ci.yml`

```yml
image: maven:3-openjdk-11

stages:
  - build
  - run

variables:
  MAVEN_CLI_OPTS: "-s .m2/settings.xml --batch-mode"
  MAVEN_OPTS: "-Dmaven.repo.local=.m2/repository"
  MOUNT_POINT: /builds/$CI_PROJECT_PATH/mnt

cache:
  paths:
    - .m2/repository/
    - target/

build:
  stage: build
  script:
    - mvn $MAVEN_CLI_OPTS compile
  tags:
    - web

run:
  stage: run
  image: docker/compose
  tags:
    - web
  script:
    - mkdir -p "$MOUNT_POINT"
    - cp -r src/main/resources/sql $MOUNT_POINT
    - docker-compose up -d --build
```

cache字段定义缓存目录，加速依赖安装及打包；部署方面使用docker-compose构建Spring Boot+mysql

MOUNT_POINT定义了用于传递数据的可挂载路径，gitlab-ci会自动导入`$CI_PROJECT_PATH`变量

### 配置`docker-compose.yml`

```yml
version: "3"

services:
  java:
    build: .
    ports:
      - "8080:8080"
    depends_on:
      - mysql

  mysql:
    image: mysql:8
    restart: always
    environment:
      MYSQL_DATABASE: pxfj
      MYSQL_ROOT_PASSWORD: $MYSQL_PASS
    volumes:
      - ${MOUNT_POINT}/sql:/docker-entrypoint-initdb.d
```

这里不能直接使用相对路径，挂载`src/main/resources/sql`的原因在于：CI过程中使用的docker-compose（本质`dind`）需要挂载`/var/run/docker.sock`，调用的是宿主机docker提供的接口，因此挂载的源路径指向的是位于宿主机的文件系统

```
                                    +----------------------------------------+
                                    |     HOST (docker-engine 1st level)     |
                                    |                                        |
                                    | /volume/for/builds # this is mounted   |
                                    |                      to all containers |
                                    |                      related to a job  |
                                    +----------------------------------------+
                                         ^                             ^
                                         |                             |
+----------------------------------------------+                 +----------------------------------------------+
|             docker:dind container            |       link      |         job container (docker:latest)        |
|                                              |---------------->|                                              |
| /       #containers root directory           | srvs_cnt:docker | /       #containers root directory           |
| /builds # builds directory mounted from host |                 | /builds # builds directory mounted from host |
+----------------------------------------------+                 +----------------------------------------------+
```

可以看到宿主机上并不存在/builds目录，直接挂载/builds/xx/xx/src/main/resources/sql会失败

~~实际测试发现，子docker会创建具有正确文件名的空文件夹，看起来似乎每个stage会共享volume，只是没有读权限（？~~

因此在启动runner时声明，把/builds目录直接映射到宿主机/builds，作为整个流程中的共享读写目录，从而实现文件的传递

这里注意一点，虽然执行CI过程中，workdir位于/builds的子目录下，但路径随机生成，并不直接位于`/builds/$CI_PROJECT_PATH`下，再加上所需要传递的通常仅是少量配置文件，直接复制的做法较为简洁明了