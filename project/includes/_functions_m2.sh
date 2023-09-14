#!/usr/bin/env bash

####################################################################################################################
# Some concepts about this file.
# It needs to be included using 'source' in a project setup script.
# It depends on variables which are declared in _config.sh.
# Once any variables declared in _config.sh have been overridden as appropriate, internal_setup_init must be called.
# Any function not prefixed 'internal_' will become available to the user for execution on the command line.
####################################################################################################################


#######################################################
# Magento 2 needs certain directories to work properly.
# Create them if they're missing.
#######################################################
internal_required_dirs_create () {
    # Phase ths step should run at.
    if [ $START_PHASE -gt 1 ] ; then
        echo_info "[!!] Skipping M2 directory fixes ...";
        return;
    fi

   # NOTHING HERE YET, PLACEHOLDER
   echo "";
}

####################################################
# Runs "tail -f" on a file in <project_root>var/log.
####################################################
m2_log:tail () {
  if [ $# -ne 1 ]; then
    echo_error "(USAGE) $(basename $0) m2_log:tail <log file name>\ne.g. $(basename $0) log:tail error.log\n";
    exit 1;
  fi

  echo_info "\n******************************************\n* Press Ctrl+C to stop watching the file *\n******************************************\n"
  ./bin/docker-exec ${php_host} "tail -f /var/www/htdocs/${vmhost_name}/var/log/$1"
}

###################################################
# Return the M2 database prefix value from env.php
#
# Required variables:
#    $vmhost_name
#    $php_host
###################################################
get_db_prefix () {
    echo $(bash ./bin/docker-exec "php -r '\$config = include \"/var/www/htdocs/${vmhost_name}/app/etc/env.php\"; echo \$config && isset(\$config[\"db\"]) && isset(\$config[\"db\"][\"table_prefix\"]) ? \$config[\"db\"][\"table_prefix\"] : \"\";'")
}

########################################
# Download a Magento 2 "env.php" file.
#
# Required variables:
#    $resources_storage
#    $vmhost_name
########################################
config:get () {
    # Phase ths step should run at.
    if [ "${START_PHASE}" -gt 2 ] ; then
        echo_info "[!!] Skipping configuration step ...";
        return;
    fi

    ./bin/docker-exec ${php_host} "mkdir -p /var/www/htdocs/${vmhost_name}/app/etc/"

    AUTH_JSON_IN_DOCKER=$(./bin/docker-exec ${php_host} "ls -l /var/www/htdocs/${vmhost_name}/auth.json | wc -l");
    if [ "s3" == "$resources_storage" ]; then
        # env.php should be stored here, not in project
        if [ "$(s3cmd ls s3://${s3_bucket}/${vmhost_name}/env.php | wc -l)" -eq 1 ]; then
          echo_info "Downloading the env.php file from S3 ..."
          mkdir -p ./project/resources/${vmhost_name}
          s3cmd get --force s3://${s3_bucket}/${vmhost_name}/env.php ./project/resources/${vmhost_name}/
          docker:copy ./project/resources/${vmhost_name}/env.php ${php_host}:/var/www/htdocs/${vmhost_name}/app/etc/env.php;
          rm -f ./project/resources/${vmhost_name}/env.php
        else
          echo_error "Failed to find env.php at s3://${s3_bucket}/${vmhost_name}/env.php";
          exit 1;
        fi

        # config.php should be in the project ... but might be overridden here
        if [ "$(s3cmd ls s3://${s3_bucket}/${vmhost_name}/config.php | wc -l)" -eq 1 ]; then
          echo_info "Downloading the config.php file from S3 ..."
          mkdir -p ./project/resources/${vmhost_name};
          s3cmd get --force s3://${s3_bucket}/${vmhost_name}/config.php ./project/resources/${vmhost_name}/
          docker:copy ./project/resources/${vmhost_name}/ ${php_host}:/var/www/htdocs/${vmhost_name}/app/etc/;
        fi

        # auth.json should be in the project but we might store it here
        if [[  "$(s3cmd ls s3://${s3_bucket}/${vmhost_name}/auth.json | wc -l)" -eq 1 && "$AUTH_JSON_IN_DOCKER" == "0" ]]; then
          echo_info "Downloading auth.json file from S3 ...";
          mkdir -p ./project/resources/${vmhost_name}
          s3cmd get --force s3://${s3_bucket}/${vmhost_name}/auth.json ./project/resources/${vmhost_name}/
          docker:copy ./project/resources/${vmhost_name}/auth.json ${php_host}:/var/www/htdocs/${vmhost_name}/auth.json;
          rm -f ./project/resources/${vmhost_name}/auth.json;
        fi

        # Check the 2 options for configuration backups
        if [ "$(s3cmd ls s3://${s3_bucket}/${vmhost_name}/configurator | wc -l)" -ne 1 ] && [ "$(s3cmd ls s3://${s3_bucket}/${vmhost_name}/dbconfig.sql.gz | wc -l)" -ne 1 ]; then
          echo_error "No database config dump and no CTI Digital configurator files found in S3... at least one is needed";
          exit 1;
        fi

        # CTI Digital Configurator files
        if [ "$(s3cmd ls s3://${s3_bucket}/${vmhost_name}/configurator | wc -l)" -eq 1 ]; then
          echo_info "Downloading CTI Configurator files ...";
          mkdir -p ./project/resources/${vmhost_name};
          ./bin/docker-exec ${php_host} "curl https://raw.githubusercontent.com/ctidigital/magento2-configurator/develop/Samples/master.yaml --output /var/www/htdocs/${vmhost_name}/app/etc/master.yaml";
          ./bin/docker-exec ${php_host} "cd /var/www/htdocs/${vmhost_name}/ && sed -i 's/\.\.\/configurator/app\/etc\/configurator/g' app/etc/master.yaml 2>/dev/null";
          s3cmd get --force --recursive s3://${s3_bucket}/${vmhost_name}/configurator ./project/resources/${vmhost_name}/;
          docker:copy ./project/resources/${vmhost_name}/configurator ${php_host}:/var/www/htdocs/${vmhost_name}/app/etc/;
          rm -rf ./project/resources/${vmhost_name}/configurator;
        fi

        # Database config backup
        if [ "$(s3cmd ls s3://${s3_bucket}/${vmhost_name}/dbconfig.sql.gz | wc -l)" -eq 1 ]; then
            echo_info "Downloading database configuration backup from S3 ...";
            s3cmd get --force s3://${s3_bucket}/${vmhost_name}/dbconfig.sql.gz  ./db_dumps/${vmhost_name}-config.sql.gz;
        fi
    elif [ "local" == "$resources_storage" ]; then
        # env.php should be stored here, not in project
        if [ -f "./project/resources/${vmhost_name}/env.php" ]; then
          echo_info "Copying the env.php file ..."
          docker:copy ./project/resources/${vmhost_name}/env.php ${php_host}:/var/www/htdocs/${vmhost_name}/app/etc/
        else
          echo_error "Failed to find env.php at ./project/resources/${vmhost_name}/env.php";
          exit 1;
        fi

        # config.php should be in the project ... but might be overridden here
        if [ -f "./project/resources/${vmhost_name}/config.php" ]; then
          echo_info "Copying the config.php file ..."
          docker:copy ./project/resources/${vmhost_name}/config.php ${php_host}:/var/www/htdocs/${vmhost_name}/app/etc/
        fi

        # auth.json should be in the project but we might store it here
        if [[ -f "./project/resources/${vmhost_name}/auth.json" && "$AUTH_JSON_IN_DOCKER" == "0" ]]; then
          echo_info "Copying auth.json file ...";
          docker:copy ./project/resources/${vmhost_name}/auth.json ${php_host}:/var/www/htdocs/${vmhost_name}/auth.json;
        fi

        # Check the 2 options for configuration backups
        if [[ ! -d "./project/resources/${vmhost_name}/configurator"  &&  ! -f "./project/resources/${vmhost_name}/dbconfig/sql.gz" ]]; then
          echo_error "No database config dump and no CTI Digital configurator files found in ./project/resources/${vmhost_name}... at least one is needed";
        fi

        # CTI Digital Configurator files
        if [ -d "./project/resources/${vmhost_name}/configurator" ]; then
          echo_info "Copying CTI Configurator files ..."
          ./bin/docker-exec ${php_host} "curl https://raw.githubusercontent.com/ctidigital/magento2-configurator/develop/Samples/master.yaml --output /var/www/htdocs/${vmhost_name}/app/etc/master.yaml";
          ./bin/docker-exec ${php_host} "cd /var/www/htdocs/ && sed -i 's/\.\.\/configurator/\.\/app\/etc\/configurator/g' ${vmhost_name}/app/etc/master.yaml 2>/dev/null";
          docker:copy ./project/resources/${vmhost_name}/configurator/ ${php_host}:/var/www/htdocs/${vmhost_name}/app/etc/;
        fi

        # Database config backup
        if [ -f "./project/resources/${vmhost_name}/dbconfig.sql.gz" ]; then
            echo_info "Copying database configuration backup from local ...";
            cp ./project/resources/${vmhost_name}/dbconfig.sql.gz  ./db_dumps/${vmhost_name}-config.sql.gz;
        fi
    else
        echo_error "Unsupported resources_storage type $resources_storage";
        exit 1;
    fi
}

config:apply () {
    # Phase ths step should run at.
    if [ "${START_PHASE}" -gt 2 ] ; then
        echo_info "[!!] Skipping apply configuration step ...";
        return;
    fi

  # Check that one of the 2 supported methods is available
  CONFIG_IN_DOCKER=$(./bin/docker-exec ${php_host} "ls -1 /var/www/htdocs/${vmhost_name}/app/etc/ | grep -e '^configurator$' | wc -l");
  if [[ ! -f "./db_dumps/${vmhost_name}-config.sql.gz" &&  "$CONFIG_IN_DOCKER" == "0" ]]; then
    echo_error "A configuration backup is required at either:\n./db_dumps/${vmhost_name}-config.sql.gz OR ${php_host}:/var/www/htdocs/${vmhost_name}/app/etc/configurator\nThis should have been obtained with config:get";
    exit 1;
  fi

  # Database config backup version
  if [ -f "./db_dumps/${vmhost_name}-config.sql.gz" ]; then
    echo_info "Database configuration backup found ...";
    docker:copy ./db_dumps/${vmhost_name}-config.sql.gz ${db_host}:/tmp/;
    ./bin/docker-exec root ${db_host} "chown mysql:mysql /tmp/${vmhost_name}-config.sql.gz";
    echo_info "Loading database configuration backup into database ${db_name} ...";
    UNPACKED_SIZE=$(./bin/docker-exec ${db_host} "gzip -l /tmp/${vmhost_name}-config.sql.gz | sed -n 2p | awk '{print \$2}'");
    ./bin/docker-exec ${db_host} "zcat /tmp/${vmhost_name}-config.sql.gz | pv --force --progress --size ${UNPACKED_SIZE} | mysql --binary-mode --force -h 127.0.0.1 -uroot -proot ${db_name}"
    ./bin/docker-exec ${db_host} "rm /tmp/${vmhost_name}.sql.gz"
  fi

  # CTI Digital Configurator version
  if [[ "$CONFIG_IN_DOCKER" == "1" ]] ; then
      echo_info "CTI Digital Configurator files found ...";
      CONFIGURATOR_ENABLED=$(./bin/docker-exec ${php_host} "cd /var/www/htdocs/${vmhost_name}/ && bin/magento module:status CtiDigital_Configurator FireGento_FastSimpleImport | grep -ci enabled")
      if [ "$CONFIGURATOR_ENABLED" == "0" ]; then
        echo_info "Enabling modules for CTI Digital Configurator";
        ./bin/docker-exec ${php_host} "cd /var/www/htdocs/${vmhost_name}/ && bin/magento module:enable CtiDigital_Configurator FireGento_FastSimpleImport"
      else
        echo_info "CTI Digital Configurator module already enabled";
      fi

      echo_info "Applying configuration with CTI Digital Configurator ...";
      ./bin/docker-exec ${php_host} "cd /var/www/htdocs/${vmhost_name}/ && bin/magento configurator:run --env=\"local\" --component=\"config\" -v"
  fi

  cache:flush;
}

###########################################################
# Composer install the CTI Digital
# Configurator for M2 (dev only).
# To allow us to set URLs etc.
# Ref : https://ctidigital.github.io/magento2-configurator/
###########################################################
composer_require_dev_tools () {
    if [ $START_PHASE -gt 3 ] ; then
        echo_info "[!!] Skipping composer install ...";
        return;
    fi

    if [[ "${resources_storage}" == "local" && -d "./project/resources/${vmhost_name}/configurator" ]] ||
       [[ "${resources_storage}" == "s3" && "$(s3cmd ls s3://${s3_bucket}/${vmhost_name}/configurator | wc -l)" -eq 1 ]]; then
      echo_info "Installing CTI Digital Configurator ...";
      ./bin/docker-exec ${php_host} "cd /var/www/htdocs/${vmhost_name}/; ${COMPOSER_COMMAND} require --no-update --dev ctidigital/magento2-configurator:3.1.3";
      ./bin/docker-exec ${php_host} "cd /var/www/htdocs/${vmhost_name}/; ${COMPOSER_COMMAND} update ctidigital/magento2-configurator";
    else
      echo_error "Failed to find configuration files in ${resources_storage}"
      exit 1;
    fi
}

####################################
# Change deploy mode of docker stack
####################################
docker:mode:set() {
    DEPLOY_MODE="$1";
    if [[ "${DEPLOY_MODE}" != "production" && "${DEPLOY_MODE}" != "developer" ]]; then
      echo_error "Valid deploy modes are 'production' or 'developer', '${DEPLOY_MODE}' received.";
      exit 1;
    fi
    echo_info "Changing docker-stack to ${DEPLOY_MODE} mode";
    PHP_BUILD_ENV=DS_services_${php_host}_build_context;
    export "$(internal_parse_services_yaml ${PHP_BUILD_ENV})";
    PHP_BUILD_ENV=${!PHP_BUILD_ENV//\"/};
    if [ -z "${PHP_BUILD_ENV}" ]; then
      echo_error "PHP container ${php_host} not defined in services yaml";
      exit 1;
    fi
    docker:copy "${PHP_BUILD_ENV}/php.ini-${DEPLOY_MODE}" ${php_host}:/usr/local/etc/php/php.ini;
    ./bin/docker-compose restart "${php_host}";
    if [[ "${DEPLOY_MODE}" == "production" && -f 'docker/nginx/Dockerfile-prod' ]]; then
      mv docker/nginx/Dockerfile docker/nginx/Dockerfile-dev && mv docker/nginx/Dockerfile-prod docker/nginx/Dockerfile;
    elif [[ "${DEPLOY_MODE}" == "developer" && -f 'docker/nginx/Dockerfile-dev' ]]; then
      mv docker/nginx/Dockerfile docker/nginx/Dockerfile-prod && mv docker/nginx/Dockerfile-dev docker/nginx/Dockerfile;
    fi
    docker:refresh
     if [[ "${DEPLOY_MODE}" == "production" ]]; then
       bin/magento config:set system/full_page_cache/caching_application 2 # setting varnish full page cache
     else
       bin/magento config:set system/full_page_cache/caching_application 1 # setting built-in full page cache
     fi
     bin/magento cache:flush

}

#####################################
# START ....
# VARIOUS bin/magento COMMANDS FOR M2
#
# Required variables:
#    $vmhost_name
#    $php_host
#####################################
bin/magento () {
      echo_info "Running bin/magento ${*} ... ";
      ./bin/docker-exec ${php_host} "cd /var/www/htdocs/${vmhost_name}/; bin/magento ${*}"
      if [[ "${*}" == *"deploy:mode:set"* ]]; then
        DEPLOY_MODE=$(echo "${*}" | awk '{print $NF}')
        docker:mode:set "${DEPLOY_MODE}";
      fi
}

#####################################
# START ....
# VARIOUS n-98magerun2 COMMANDS FOR M2
#
# Required variables:
#    $vmhost_name
#    $php_host
#####################################
n98-magerun2 () {
      echo_info "Running n98-magerun2 ${*} ... ";
      ./bin/docker-exec ${php_host} "cd /var/www/htdocs/${vmhost_name}/; n98-magerun2 ${*}"
}

sampledata:deploy () {
      REPO_MAGENTO_IN_DOCKER=$(./bin/docker-exec ${php_host} "grep 'repo.magento.com' /var/wwww/htdocs/${vmhost_name}/composer.json | wc -l");
      if [[ "$REPO_MAGENTO_IN_DOCKER" == "0" ]]; then
        echo "Adding repo.magento.com composer repository ...";
        ./bin/docker-exec ${php_host} "cd /var/www/htdocs/${vmhost_name}/; ${COMPOSER_COMMAND} config repositories.0 composer https://repo.magento.com"
      fi
      echo_info "Running bin/magento sampledata:deploy ... ";
      ./bin/docker-exec ${php_host} "cd /var/www/htdocs/${vmhost_name}/; bin/magento -n sampledata:deploy"
}

setup:upgrade () {
    echo_info "Running bin/magento setup:upgrade ... ";
    ./bin/docker-exec ${php_host} "cd /var/www/htdocs/${vmhost_name}/; bin/magento setup:upgrade"
}

di:compile () {
    echo_info "Running bin/magento setup:di:compile ... ";
    ./bin/docker-exec ${php_host} "cd /var/www/htdocs/${vmhost_name}/; bin/magento setup:di:compile"
}

cache:clean () {
    echo_info "Running bin/magento cache:clean ... ";
    ./bin/docker-exec ${php_host} "cd /var/www/htdocs/${vmhost_name}/; bin/magento cache:clean"
}

cache:flush () {
    echo_info "Running bin/magento cache:flush ... ";
    ./bin/docker-exec ${php_host} "cd /var/www/htdocs/${vmhost_name}/; bin/magento cache:flush"
}

cache:enable () {
    echo_info "Running bin/magento cache:enable ${*}... ";
    ./bin/docker-exec ${php_host} "cd /var/www/htdocs/${vmhost_name}/; bin/magento cache:enable ${*}"
}

cache:disable () {
    echo_info "Running bin/magento cache:enable ${*}... ";
    ./bin/docker-exec ${php_host} "cd /var/www/htdocs/${vmhost_name}/; bin/magento cache:disable ${*}"
}

indexer:reindex () {
      echo_info "Running bin/magento index:reindex ${*}... ";
      ./bin/docker-exec ${php_host} "cd /var/www/htdocs/${vmhost_name}/; bin/magento indexer:reindex ${*}"
}
#####################################
# END ....
# VARIOUS bin/magento COMMANDS FOR M2
#####################################

####################################
# Create an admin user 'dev-vm'
# password 'dev-vm'
#
# Required variables:
#    $vmhost_name
#    $php_host
####################################
create_admin_user () {
    if [ "$START_PHASE" -gt "2" ] ; then
        echo_info "[!!] Skipping creation of admin user ...";
        return;
    fi

    auth_role_count=$(./bin/docker-exec ${db_host} "mysql -h 127.0.0.1 -uroot -proot ${db_name} -N -e \"SELECT count(*) FROM authorization_role\" 2>/dev/null" | awk '{print $1}')
    auth_rule_count=$(./bin/docker-exec ${db_host} "mysql -h 127.0.0.1 -uroot -proot ${db_name} -N -e \"SELECT count(*) FROM authorization_rule\" 2>/dev/null" | awk '{print $1}')
    if [ "${auth_role_count}" -eq "0" ] && [ "${auth_rule_count}" -eq "0" ]; then
      echo_warn "Authorisation role and rule missing ...";
      echo_info "recreating authorisation role and rule for Administrators ...";
      ./bin/docker-exec ${db_host} "mysql -h 127.0.0.1 -uroot -proot ${db_name} -N -e \"INSERT INTO authorization_role (role_id, parent_id, tree_level, sort_order, role_type, user_id, user_type, role_name) VALUES (1, 0, 1, 1, 'G', 0, '2', 'Administrators')\""
      ./bin/docker-exec ${db_host} "mysql -h 127.0.0.1 -uroot -proot ${db_name} -N -e \"INSERT INTO authorization_rule (rule_id, role_id, resource_id, privileges, permission) VALUES (1, 1, 'Magento_Backend::all', null, 'allow')\""
      cache:flush
    fi

    echo_info "Creating admin user ...";
    ./bin/docker-exec ${php_host} "cd /var/www/htdocs/${vmhost_name}/; bin/magento admin:user:create --admin-user=\"dev-vm\" --admin-password=\"dev-vm123\" --admin-email=\"noreply@lemp.dm\" --admin-firstname=\"Development\" --admin-lastname=\"User\" --magento-init-params=\"1\";" ;
    echo "

#####################################
# Magento Admin user has been created
#
# username : dev-vm
# password : dev-vm123
#####################################
    ";
}

#########################################################
# Resolve error : The following modules are outdated
#
# Function requires 1 argument (module to delete from db)
#########################################################
fix_outdated_error () {
    # Phase ths step should run at.
    if [ $START_PHASE -gt 3 ] ; then
        echo_info "[!!] Skipping setup_module fix for $1 ....";
        return;
    fi

    db_prefix=$(m2_get_db_prefix);
    echo_info "Removing $1 from setup_module ... ";
    ./bin/docker-exec ${db_host} "mysql -h 127.0.0.1 -uroot -proot ${db_name} -e \"DELETE FROM ${db_prefix}setup_module WHERE module = '$1'\"";
}

#############################################################
# Resolve error : e.g. css file "Requested path ... is wrong"
#
# Function requires 1 argument (module to delete from db)
#############################################################
disable_dev_static_sign () {
    # Phase ths step should run at.
    if [ $START_PHASE -gt 2 ] ; then
        echo_info "[!!] Skipping dev/static/sign config change ....";
        return;
    fi

    echo_info "Disabling dev/static/sign in config ... ";
    ./bin/docker-exec ${db_host} "mysql -h 127.0.0.1 -uroot -proot ${db_name} -e \"UPDATE ${db_prefix}core_config_data SET value=0 WHERE path='dev/static/sign'\"";
    ./bin/docker-exec ${php_host} "cd /var/www/htdocs/${vmhost_name} && bin/magento config:set --lock-env dev/static/sign 0";
}
