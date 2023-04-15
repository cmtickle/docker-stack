FROM ubuntu:18.04 AS builder
RUN \
  apt-get update \
  && apt-get install -y \
    pv \
    gzip \
    util-linux

FROM mysql:5.7

USER root

COPY --from=builder /bin/gzip /bin/gzip
COPY --from=builder /bin/zcat /bin/zcat
COPY --from=builder /usr/bin/pv /usr/bin/pv
COPY --from=builder /usr/bin/whereis /usr/bin/whereis

USER mysql
