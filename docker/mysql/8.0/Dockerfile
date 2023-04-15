FROM ubuntu:18.04
RUN \
  apt-get update \
  && apt-get install -y \
    pv \
    gzip \
    util-linux

FROM mysql/mysql-server:8.0

COPY --from=0 /bin/gzip /bin/gzip
COPY --from=0 /bin/zcat /bin/zcat
COPY --from=0 /usr/bin/pv /usr/bin/pv
COPY --from=0 /usr/bin/whereis /usr/bin/whereis

USER root

USER mysql
