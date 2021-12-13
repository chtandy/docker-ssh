FROM ubuntu:20.04
MAINTAINER cht.andy@gmail.com

ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=Asia/Taipei
## 變更預設的dash 為bash
RUN set -eux \
  && echo "######### change default sh dash to bash ##########" \
  && mv /bin/sh /bin/sh.old && ln -s /bin/bash /bin/sh

## 安裝locales 與預設語系
RUN set -eux \
  && echo "######### apt install locales and timezone ##########" \
  && apt-get update && apt-get install --assume-yes locales tzdata bash-completion \
  && rm -rf /var/lib/apt/lists/* && apt-get clean \
  && locale-gen zh_TW.UTF-8 && update-locale LANG=zh_TW.UTF-8 \
  && ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone

## 安裝sshd
RUN set -eux \
  && echo "######### apt install sshd ##########" \
  && apt-get update \
  && apt-get install --assume-yes openssh-client openssh-server sudo \
  && rm -rf /var/lib/apt/lists/* && apt-get clean \
  && sed -i 's|#PasswordAuthentication yes|PasswordAuthentication no|' /etc/ssh/sshd_config \
  && mkdir -p /run/sshd \
  && cp /etc/sudoers /etc/sudoers.bak \
  && sed -i 's|^[%]sudo.*|%sudo  ALL=(ALL:ALL) NOPASSWD: ALL|' /etc/sudoers \
  && { \
     echo "    StrictHostKeyChecking no"; \
     echo "    UserKnownHostsFile /dev/null"; \
     } >> /etc/ssh/ssh_config 

## 新增user 並給予sudo, root 權限
ARG USERNAME
ARG USER_ID
RUN set -eux \
  && echo "######### useradd ${USERNAME} ##########" \
  && apt-get update \
  && apt install --assume-yes sudo \
  && rm -rf /var/lib/apt/lists/* && apt-get clean \
  && useradd -m -G sudo,root -u ${USER_ID} -s /bin/bash ${USERNAME} \
  && echo "${USERNAME} ALL=NOPASSWD: ALL" >> /etc/sudoers

ENTRYPOINT ["/usr/sbin/sshd", "-D"]
