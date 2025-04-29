FROM golang:1.15 AS builder

RUN go get -d -v github.com/mailhog/mhsendmail \
  && cd /go/src/github.com/mailhog/mhsendmail/ \
  && GOOS=linux GOARCH=$TARGETARCH go build -o mhsendmail .

FROM php:8.4-fpm
ARG USERID=1000
ARG GROUPID=1000
RUN groupmod -g 999 dialout

# fix www-data user to avoid permissions issues
RUN mkdir -p /var/www/htdocs
RUN usermod -u $USERID --home /var/www/htdocs/ www-data
RUN groupmod -g $GROUPID www-data
RUN chown www-data: /var/www/htdocs

RUN apt-get update \
  && apt-get install -y \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libmagickwand-dev \
    libmcrypt-dev \
    libonig-dev \
    libpng-dev \
    libxslt1-dev \
    libzip-dev \
    unzip \
    sendmail-bin \
    sendmail \
    sudo \
    cron \
    rsyslog \
    default-mysql-client \
    git \
    gnupg2 \
    vim

# Blackfire
#RUN version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
#    && architecture=$(case $(uname -m) in i386 | i686 | x86) echo "i386" ;; x86_64 | amd64) echo "amd64" ;; aarch64 | arm64 | armv8) echo "arm64" ;; *) echo "amd64" ;; esac) \
#    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/$architecture/$version \
#    && mkdir -p /tmp/blackfire \
#    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp/blackfire \
#    && mv /tmp/blackfire/blackfire-*.so $(php -r "echo ini_get ('extension_dir');")/blackfire.so \
#    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8707\n" > /usr/local/etc/php/conf.d/blackfire.ini \
#    && rm -rf /tmp/blackfire /tmp/blackfire-probe.tar.gz

# Install latest Node.js
RUN curl -sL https://deb.nodesource.com/setup_18.x  | bash -
RUN apt-get -y install nodejs

# INSTALL YARN
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt update && \
    apt install -y yarn

# Configure the gd library
RUN docker-php-ext-configure \
  gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/

# Install required PHP extensions
RUN docker-php-ext-install \
  dom \
  gd \
  intl \
  mbstring \
  pdo_mysql \
  mysqli \
  xsl \
  zip \
  soap \
  bcmath \
  sockets

#IMAGEMAGICK
RUN pecl install imagick \
    && docker-php-ext-enable imagick

#OPCACHE
RUN docker-php-ext-configure opcache --enable-opcache \
    && docker-php-ext-install opcache

#PHPREDIS
RUN pecl install -o -f redis \
    &&  rm -rf /tmp/pear \
    &&  docker-php-ext-enable redis

# INSTALL COMPOSER VERSIONS
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer1 --version=1.10.19
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer2 --version=2.1.14

# MAGERUN
RUN curl -O https://files.magerun.net/n98-magerun.phar \
    && chmod +x n98-magerun.phar \
    && mv n98-magerun.phar /usr/local/bin/n98-magerun1

RUN curl -O https://files.magerun.net/n98-magerun2.phar \
    && chmod +x n98-magerun2.phar \
    && mv n98-magerun2.phar /usr/local/bin/n98-magerun2

# INSTALL GRUNT
RUN npm install -g grunt-cli

#INSTALL PLAYWRIGHT FOR CRITICAL CSS
RUN apt-get update \
  && apt-get install -y \
    libnss3\
    libnspr4\
    libgbm1\
    libasound2

#XDEBUG
RUN pecl install xdebug-3.2.1 \
    && echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini
RUN echo "xdebug.remote_autostart=off" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.client_host=host.docker.internal" >>  /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.client_port=9000" >>  /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.start_with_request=trigger" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.show_error_trace=1" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.discover_client_host=1" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.idekey=\"PHPSTORM\"" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.discover_client_host=1" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.log=\"/tmp/xdebug.log\"" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.output_dir=\"/tmp/\"" >> /usr/local/etc/php/conf.d/xdebug.ini

# Add base php.ini and php-fpm config
ADD php.ini-developer /usr/local/etc/php/php.ini
ADD www.conf /usr/local/etc/php-fpm.d/www.conf
ADD zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf

# MHSENDMAIL
COPY --from=builder /go/src/github.com/mailhog/mhsendmail/mhsendmail /usr/bin/
RUN chmod +x /usr/bin/mhsendmail \
    && echo 'sendmail_path = "/usr/bin/mhsendmail --smtp-addr=\"mailhog:1025\" --from=\"demophp81@example.com\""' >> /usr/local/etc/php/php.ini

# Docker CLI for docker-stack UI
COPY --from=docker:20.10 /usr/local/bin/docker /usr/local/bin/
# required packages for docker-stack including Docker Compose
RUN apt-get install -y bc && \
    curl -L -o docker-compose "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" && \
    mv docker-compose /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose
