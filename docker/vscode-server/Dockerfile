FROM ubuntu:20.04

ARG USERID=1000
ARG GROUPID=1000
RUN groupmod -g 999 dialout

ENV CODE_SERVER_VERSION 4.11.0

# fix www-data user to avoid permissions issues
RUN mkdir -p /var/www/htdocs
RUN usermod -u $USERID --home /var/www/htdocs www-data
RUN groupmod -g $GROUPID www-data
RUN chown -R www-data: /var/www/htdocs

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y \
    ca-certificates sudo curl dumb-init \
    git vim \
    lsb-release \
    wget \
    openssl \
    php-codesniffer

RUN ARCH="$(dpkg --print-architecture)" && wget https://github.com/cdr/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server_${CODE_SERVER_VERSION}_${ARCH}.deb \
  && dpkg -i code-server_${CODE_SERVER_VERSION}_amd64.deb && rm -f code-server_${CODE_SERVER_VERSION}_${ARCH}.deb \
  && rm -rf /var/lib/apt/lists/*


RUN git config --global core.fileMode false
RUN touch /var/www/htdocs/.bashrc && chown www-data: /var/www/htdocs/.bashrc && chsh -s /usr/bin/bash www-data


ADD entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh && \
    chown www-data: /usr/bin/entrypoint.sh

RUN mkdir -p /var/www/htdocs/certs
ADD certs/. /var/www/certs
RUN chown -R www-data: /var/www/certs


ADD settings.json /var/www/htdocs/.local/share/code-server/User/settings.json
RUN chown -R www-data: /var/www/htdocs/.local/share/code-server/User/settings.json

USER www-data
ENV USER=www-data
WORKDIR /var/www/htdocs

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
