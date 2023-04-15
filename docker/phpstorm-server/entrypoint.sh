#!/usr/bin/env bash

if [ -z "$RUNNING_PROJECT" ]; then
  echo -e "RUNNING_PROJECT is not defined\nSTART WITH:\nRUNNING_PROJECT=RUNNING_PROJECT docker-compose up phpstorm-server";
  exit 1;
fi

if [ ! -d "/var/www/htdocs/${RUNNING_PROJECT}" ]; then
  echo "ERROR: PROJECT '${RUNNING_PROJECT}' NOT FOUND";
  exit 1;
fi

if [ ! -d "/var/www/htdocs/${RUNNING_PROJECT}/.idea/" ]; then
  cp -r /idea/.idea-base "/var/www/htdocs/${RUNNING_PROJECT}/.idea/";
  mv "/var/www/htdocs/${RUNNING_PROJECT}/.idea/project-magento.iml" "/var/www/htdocs/${RUNNING_PROJECT}/.idea/${RUNNING_PROJECT}.iml";
  sed -i "s/project-magento/${RUNNING_PROJECT}/g" "/var/www/htdocs/${RUNNING_PROJECT}/.idea/modules.xml"
fi

/ide/bin/remote-dev-server.sh warm-up "/var/www/htdocs/${RUNNING_PROJECT}/"
/ide/bin/remote-dev-server.sh run "/var/www/htdocs/${RUNNING_PROJECT}/" --ssh-link-user www-data --listenOn 0.0.0.0 --port 5993 2>/dev/null
