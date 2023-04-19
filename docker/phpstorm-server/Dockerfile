FROM ubuntu:20.04

ARG USERID=1000
ARG GROUPID=1000
RUN groupmod -g 999 dialout

RUN mkdir -p /var/www/htdocs
RUN usermod -u $USERID --home /var/www/htdocs/ www-data
RUN groupmod -g $GROUPID www-data
RUN chown www-data: /var/www/

RUN echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y git curl unzip procps time mc strace git
WORKDIR /tmp
ARG IDEA_BUILD=223.8617.59
RUN curl -fsSL -o /tmp/ide.tar.gz https://download-cdn.jetbrains.com/webide/PhpStorm-2022.3.2.tar.gz && \
    mkdir /ide && \
    tar xfz /tmp/ide.tar.gz --strip-components=1 -C /ide && \
    rm /tmp/ide.tar.gz

RUN /ide/bin/remote-dev-server.sh installPlugins /var/www/htdocs com.magento.idea.magento2plugin

# Enable JCEF (embedded Chromium) for e.g. markdown preview
ENV REMOTE_DEV_SERVER_JCEF_ENABLED=1

RUN git config --global core.fileMode false

ADD entrypoint.sh /ide/entrypoint.sh
ADD .idea /idea/.idea-base
RUN chmod +x /ide/entrypoint.sh
RUN chown -R www-data: /ide

CMD ["bash", "/ide/entrypoint.sh"]
