FROM nginx:1.25
ARG USERID=1000
ARG GROUPID=1000
RUN groupmod -g 999 dialout

# fix www-data user to avoid permissions issues
RUN usermod -u $USERID nginx
RUN groupmod -o -g $GROUPID nginx

ADD nginx.conf /etc/nginx/nginx.conf
ADD default.conf /etc/nginx/conf.d/default.conf
ADD m-hosts.conf /etc/nginx/conf.d/z-m-hosts.conf
ADD m-servers.conf /etc/nginx/conf.d/z-m-servers.conf
ADD m-certs.conf /etc/nginx/conf.d/z-m-certs.conf

# SSL
ADD certs/* /etc/ssl/certs/
ADD certs/* /etc/ssl/private/
RUN whoami
RUN chown -R -f nginx: /etc/ssl /var/cache/nginx /var/log/nginx /var/run /var/run/*

EXPOSE 443
