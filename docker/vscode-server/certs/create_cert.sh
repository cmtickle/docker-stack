#!/bin/sh

sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout 0.0.0.0.key -out 0.0.0.0.crt -config 0.0.0.0.conf
sudo chown ${USER}: 0.0.0.0.crt 0.0.0.0.key
