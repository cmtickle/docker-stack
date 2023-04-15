#!/usr/bin/env bash

if [ -z "$RUNNING_PROJECT" ]; then
  echo -e "RUNNING_PROJECT is not defined\nSTART WITH:\nRUNNING_PROJECT=RUNNING_PROJECT docker-compose up phpstorm-server";
  exit 1;
fi

EXTENSIONS=redhat.vscode-yaml,vscode-icons-team.vscode-icons

mkdir -p /var/www/htdocs/.config/code-server/
cat > /var/www/htdocs/.config/code-server/config.yaml << EOF
bind-addr: 0.0.0.0:8433
auth: none
cert: false
EOF

echo "Installing Extensions"
for extension in $(echo ${EXTENSIONS} | tr "," "\n")
  do
    if [ "${extension}" != "" ]
      then
        dumb-init /usr/bin/code-server \
          --install-extension  "${extension}" --force \
          /var/www/htdocs
    fi
  done

/usr/bin/code-server \
  --auth none \
  --bind-addr "0.0.0.0":"8443" \
#  --cert /var/www/certs/0.0.0.0.crt \
#  --cert-key /var/www/certs/0.0.0.0.key \
  "/var/www/htdocs/${RUNNING_PROJECT}/"
