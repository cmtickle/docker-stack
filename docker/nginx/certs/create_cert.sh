#!/bin/sh

sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout loc.key -out loc.crt -config loc.conf
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout local.key -out local.crt -config local.conf
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout localhost.key -out localhost.crt -config localhost.conf

