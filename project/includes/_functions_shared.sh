#!/usr/bin/env bash

# Allow access to shared functions from 'bin' scripts too
source ./bin/_shared.sh;

####################################################################################################################
# Some concepts about this file.
# It needs to be included using 'source' in a project setup script.
# It depends on variables which are declared in _config.sh.
# Once any variables declared in _config.sh have been overridden as appropriate, internal_setup_init must be called.
# Any function not prefixed 'internal_' will become available to the user for execution on the command line.
####################################################################################################################

#################################################
# MUST BE CALLED BEFORE USING ANY OTHER FUNCTIONS
#################################################
internal_setup_init () {
    internal_verify_bash_version;
    internal_verify_auth_json;
    internal_verify_docker_available;

    echo_info "Initialising project script ..."

    ##############################################
    # Array to contain a list of defined functions
    ##############################################
    functions=($(compgen -A function | grep -v -e "^internal_\|^echo_info$\|^echo_warn$\|^echo_error$" | sort | tr "\r\n" " "));

    ###############################################
    ###############################################
    # Allow the user to start run specific portions
    # of the setup script.
    ###############################################
    if [ ${#BASH_ARGV[@]} -lt 1 ]; then
        echo_info "
USAGE: ${BASH_SOURCE[1]} <start_phase/custom_function>
You MUST provide the parameter 'start_phase' OR 'custom_function' to this script.

This script contains 3 phases of installation:
files    : Download the codebase, run any additional commands to get the code structure ready for running.
database : Downloads a copy of the database and configuration then loads these into the correct container.
install  : Any final tasks required to get make the codebase operational e.g. composer or bin/magento

<start_phase> supported options ::

setup:all       = file, database and install phase functions
setup:database  = database and install phase functions ONLY
setup:install   = install phase functions ONLY

<custom_function> supported options ::
";
        for func in "${functions[@]}"; do
          echo "$func";
        done

        exit 1;
    fi

    # DEFINE COMPOSER COMMAND
    if [ "$composer_version" == "1" ]; then
       COMPOSER_COMMAND="composer1"
    elif [ "$composer_version" == "2" ]; then
       COMPOSER_COMMAND="composer2"
    else
       echo_error "ERROR : Unsupported composer version : $composer_version";
       exit 1;
    fi

    # Bash arguments act as a "stack", so parameters are reversed.
    # This is not useful if we want to use those parameters as arguments for functions.
    # So we create a reversed version of the parameters as ...
    # ...
    # BASH_ARGVS
    for (( i=${#BASH_ARGV[@]}-1;i>=0;i-- ));do
       pos=$(echo ${#BASH_ARGV[@]}-1-$i | bc)
       BASH_ARGVS[$pos]=${BASH_ARGV[$i]};
    done

    # If a valid function name was provided, run the function and exit.
    if [[ "${functions[*]}" =~ ${BASH_ARGVS[0]} ]]; then
      echo_info "Running function \"${BASH_ARGVS[*]}\" ...";
      START_PHASE=1;
      ${BASH_ARGVS[*]} ;
      exit $?;
    fi
    START_PHASE=${BASH_ARGVS[0]}

    # Map the phases to a number so we can compare with less than or equals to.
    # PHASE 1 = files/all (STEPS : files, database, install);
    # PHASE 2 = database (STEPS : database, install);
    # PHASE 3 = install (STEPS: install ONLY);
    if [ "$START_PHASE" == "setup:all" ]; then
        START_PHASE=1;
    elif [ "$START_PHASE" == "setup:database" ]; then
        START_PHASE=2;
    elif [ "$START_PHASE" == "setup:install" ]; then
        START_PHASE=3;
    else
        echo_error "Unsupported start phase : $START_PHASE";
        exit 1;
    fi

    echo_info "Running ${BASH_ARGVS[0]}";
}

###################################
# Functions to check pre-requisites
###################################
internal_verify_bash_version () {
      bash_version=${BASH_VERSION}
      bash_version=$(echo ${bash_version//[!0-9.]/} | xargs printf "%.2f" 2>/dev/null);
      bash_version=${bash_version/,/.};
      if (( $(echo "${bash_version} < 4.30" | bc -l) )); then
        echo_error "Bash version 4.3-alpha or later is required.";
        exit 1;
      else
        echo_info "Running supported bash version (${bash_version})";
      fi
}

internal_verify_auth_json () {
  AUTH_JSON_FILE="./project/resources/${vmhost_name}/auth.json";
  if [ -f "$AUTH_JSON_FILE" ]; then
    AUTH_JSON_IS_DEFAULT=$(grep -c 'XXXX' $AUTH_JSON_FILE);
    if [ "${AUTH_JSON_IS_DEFAULT}" -ne 0 ]; then
      echo_error "Please add your credentials in $AUTH_JSON_FILE";
      exit 1;
    fi
  fi
}

internal_verify_docker_available () {
  docker_ps_error=$(docker ps 1>/dev/null 2>&1);
  docker_ps_status=${?};
  if [ "${docker_ps_status}" -eq 127 ]; then
    echo_error "\"docker\" command not found";
    exit 1;
  elif [ "${docker_ps_error}" != "" ]; then
    echo_error "Docker ps error : \"${docker_ps_error}\". Are you sure docker is running?";
    exit 1;
  fi
}

internal_verify_container_is_up () {
  if [ "$1" = "" ]; then
    echo_error "function 'internal_verify_container_is_up' requires an argument, none given";
    exit 1;
  fi
  container_id=$(./bin/docker-compose ${docker_compose_args} ps -q "${1}");
  if [ "$(docker ps -q --no-trunc | grep "${container_id}")" != "" ]; then
    echo "Up";
  else
    echo "Down";
  fi
}

internal_verify_required_containers_are_up () {
  all_up=true;
  for required_container in "${required_containers[@]}"
  do
    if [ $(internal_verify_container_is_up ${required_container}) == "Down" ]; then
      echo_error "Container \"${required_container}\" is not running.";
      all_up=false;
    fi
  done

  if [ ${all_up} == false ]; then
    exit 1;
  else
    echo_info "Required containers (${required_containers[*]}) are running.";
  fi
}
##########################################
# End of functions to check pre-requisites
##########################################

#################################
# HELPERS FOR ECHOING INFORMATION
#################################
# COLOURS FOR ECHO
RED='\033[0;31m';
GREEN='\033[0;32m';
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
echo_info () {
  echo -e "\n${GREEN}INFO: ${1}${NC}";
}

echo_warn () {
  echo -e "\n${YELLOW}WARN: ${1}${NC}";
}

echo_error () {
  echo -e "\n${RED}ERROR: ${1}${NC}";
}

######################################################
# CREDIT: https://stackoverflow.com/a/21189044/7762309
######################################################
function internal_parse_services_yaml {
   local prefix="DS_";
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   ./bin/docker-compose config |
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"   |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }' | grep "$1";
}

##############################################
# Helper function to find the docker container
# name of a docker-compose container.
##############################################
internal_docker_container_name () {
  echo $(./bin/docker-compose ${docker_compose_args} ps -q $1 | tail -1 2>/dev/null);
}

######################################################
# There's no docker-compose equivalent of "docker cp".
# This bash function aims to remove that limitation.
#
# USAGE :
# docker:copy docker_container:/remote/file /local/file
# OR
# docker:copy /local/file docker_container:/remote/file
######################################################
docker:copy () {
  from_parts=($(echo ${1} | tr ":" "\n"))
  if [ ${#from_parts[@]} -eq 2 ]; then
    from=$(internal_docker_container_name ${from_parts[0]}):${from_parts[1]};
  else
    from=${1};
  fi

  to_parts=($(echo ${2} | tr ":" "\n"));
  if [ ${#to_parts[@]} -eq 2 ]; then
    to=$(internal_docker_container_name ${to_parts[0]}):${to_parts[1]};
  else
    to=${2};
  fi

  echo_info "Docker copying ${from} ${to}";
  docker cp ${from} ${to};
}

######################################
# Build the required docker containers
######################################
docker:build () {
  ./bin/docker-compose ${docker_compose_args} build ${required_containers[*]}
}

######################################
# Start the required docker containers
######################################
docker:start () {
   ./bin/docker-compose ${docker_compose_args} up -d ${required_containers[*]};
  aliases=();
    for f in $(docker exec -it docker-stack_nginx_1 bash -c "cd /var/www/htdocs; ls -d *.{loc,local,localhost} 2>/dev/null")
      do
        aliases+=("--alias ${f} ");
    done
    nginx_container=$(./bin/docker-compose ps -q nginx);
    docker network disconnect docker_default "$nginx_container";
    docker network connect ${aliases[@]} docker_default "$nginx_container";
}

############################
# Stop all Docker containers
############################
docker:stop () {
  ./bin/docker-compose ${docker_compose_args} stop
}

############################################
# Show the status of all required containers
############################################
docker:status () {
  ./bin/docker-compose ${docker_compose_args} ps ${required_containers[*]}
}

############################
# Restart all Docker containers
############################
docker:restart () {
  docker:stop && docker:start
}

##########################################
# Show the status of all Docker containers
##########################################
docker:status_all () {
  ./bin/docker-compose ${docker_compose_args} ps
}

docker:refresh () {
  docker:build;
  docker:start;
}

access:php () {
  CONTAINER=${php_host};
  internal_set_USER_by_CONTAINER
  docker exec -it -w "/var/www/htdocs/${vmhost_name}" -u ${USER} $(internal_docker_container_name ${php_host}) bash
}

access:mysql () {
  CONTAINER=${db_host};
  internal_set_USER_by_CONTAINER
  docker exec -it -u $USER $(internal_docker_container_name ${db_host}) mysql -h 127.0.0.1 -u ${db_user} -p${db_password} ${db_name}
}

####################
# REMOTE IDE SUPPORT
####################
IDE:phpstorm () {
  RUNNING_PROJECT=${vmhost_name} ./bin/docker-compose build phpstorm-server && \
  RUNNING_PROJECT=${vmhost_name} ./bin/docker-compose up phpstorm-server
}

IDE:vscode () {
      echo -e "
  ${YELLOW}
  ####################################
  # Please add host entry.
  #
  # When the Docker build process states
  # 0.0.0.0 URL is available, access:
  # http://vscode.loc
  #
  # MAC/LINUX:
  # 127.0.0.1 vscode.loc
  #
  # WINDOWS:
  # 192.168.99.100 vscode.loc
  ####################################${NC}\n";

  RUNNING_PROJECT=${vmhost_name} ./bin/docker-compose build vscode-server && \
  RUNNING_PROJECT=${vmhost_name} ./bin/docker-compose up vscode-server
}

######################################################
# Create local clone of CVS Repository
#
# Required variables:
#     $repo_type
#     $project_name
#     $vmhost_name
######################################
repository:clone () {
    # Phase ths step should run at.
    if [ ${START_PHASE} -gt 1 ] ; then
        echo_warn "[!!] Skipping ${repo_type} clone ...";
        return;
    fi

    PROJECT_CLONED=$(./bin/docker-exec ${php_host} "ls -1 /var/www/htdocs/ | grep -e '^${vmhost_name}$' | wc -l");
    if [ "$PROJECT_CLONED" == "1" ]; then
        echo_info "Removing previous ${repo_type} clone";
        ./bin/docker-exec root ${php_host} "rm -rf /var/www/htdocs/${vmhost_name}";
    fi

    if [ 'github' == $repo_type ]; then
        echo_info "Cloning the codebase from Github ...";
        ./bin/docker-exec ${php_host} "git clone --branch ${cvs_branch} ${github_args} git@github.com:${cvs_organisation}/${project_name}.git /var/www/htdocs/${vmhost_name}";
        if [ $? -ne 0 ]; then
          echo_error "Failed to clone repository";
          exit 1;
        fi
    elif [ 'bitbucket' == $repo_type ]; then
        echo_info "Cloning the codebase from Bitbucket ...";
        ./bin/docker-exec ${php_host} "git clone --branch ${cvs_branch} ${bitbucket_args} git@bitbucket.org:${cvs_organisation}/${project_name}.git /var/www/htdocs/${vmhost_name}";
        if [ $? -ne 0 ]; then
          echo_error "Failed to clone repository";
          exit 1;
        fi
    elif [ 'custom' == $repo_type ]; then
        echo_info "Cloning the codebase from ${cvs_custom_url} ...";
        ./bin/docker-exec ${php_host} "git clone --branch ${cvs_branch} ${cvs_custom_url} /var/www/htdocs/${vmhost_name}";
        if [ $? -ne 0 ]; then
          echo_error "Failed to clone repository";
          exit 1;
        fi
    else
        echo_error "Unsupported CVS repository type $repo_type";
        exit 1;
    fi
}

################################
# Download the database backups.
#
# Required variables:
#    $resource_server_ssh
#    $vmhost_name
################################
db:get () {
    # Phase ths step should run at.
    if [ $START_PHASE -gt 2 ] ; then
        echo_info "[!!] Skipping database downloads ...";
        return;
    fi

    if [ "s3" == $resources_storage ]; then
        echo_info "Downloading latest database dump ..."
        if [ "$(s3cmd ls s3://${s3_bucket}/${vmhost_name}/${db_file} | wc -l)" -lt 1 ]; then
          echo_error "Required default database backup $db_file is missing from S3";
          exit 1;
        fi
        available_dbs=($(s3cmd ls s3://${s3_bucket}/${vmhost_name}/ | grep \\.sql.gz | sed 's/^.*\///g'))
        if [ ${#available_dbs[@]} -gt 1 ]; then
          echo -e "\n${YELLOW}Please select the DB backup to use (${#available_dbs[@]} available):${NC}"
          select chosen_db_file in ${available_dbs[*]}
          do
            break;
          done
          echo $chosen_db_file;
        fi

        if [ "$chosen_db_file" != "" ]; then
          db_file=$chosen_db_file;
        fi
        s3cmd get --force s3://${s3_bucket}/${vmhost_name}/${db_file} ./db_dumps/${vmhost_name}.sql.gz
    elif [ "local" == $resources_storage ]; then
        echo_info "Copying latest database dump from local ..."
        if [ "$(ls ./project/resources/${vmhost_name}/${db_file}| wc -l)" -lt 1 ]; then
          echo_error "Required default database backup $db_file is missing from ./project/resources/${vmhost_name}/";
          exit 1;
        fi
        available_dbs=($(ls ./project/resources/${vmhost_name}/ | grep \\.sql.gz | sed 's/^.*\///g'))
        if [ ${#available_dbs[@]} -gt 1 ]; then
          echo -e "\n${YELLOW}Please select the DB backup to use (${#available_dbs[@]} available):${NC}"
          select chosen_db_file in ${available_dbs[*]}
          do
            break;
          done
          echo $chosen_db_file;
        fi

        if [ "$chosen_db_file" != "" ]; then
          db_file=$chosen_db_file;
        fi
        cp ./project/resources/${vmhost_name}/${db_file} ./db_dumps/${vmhost_name}.sql.gz
    else
        echo_error "Unsupported resources_storage  type $resources_storage";
        exit 1;
    fi
}

##################################################
# Load the db backups into the database container.
#
# Required variables:
#     $db_host
#     $db_name
##################################################
db:load () {
    # Phase ths step should run at.
    if [ $START_PHASE -gt 2 ] ; then
        echo_info "[!!] Skipping database load ...";
        return;
    fi

    echo_info "Copying database backup into database container (${db_host}) ...";
    # Copy the backup into the container for faster load time.
    if [ -f "./db_dumps/${vmhost_name}.sql.gz" ]; then
      docker:copy ./db_dumps/${vmhost_name}.sql.gz ${db_host}:/tmp/
      ./bin/docker-exec root ${db_host} "chown mysql:mysql /tmp/${vmhost_name}.sql.gz"

      # Create a fresh database to load into.
      echo_info "Dropping and recreating database ${db_name} ...";
      ./bin/docker-exec ${db_host} "mysql -h 127.0.0.1 -u${db_user} -p${db_password} -e \"DROP DATABASE IF EXISTS ${db_name}\"";
      ./bin/docker-exec ${db_host} "mysql -h 127.0.0.1 -u${db_user} -p${db_password} -e \"CREATE DATABASE ${db_name}\"";

      # Load the file from /tmp of container into MySQL.
      echo_info "Loading database backup into database ${db_name} ...";
      UNPACKED_SIZE=$(./bin/docker-exec ${db_host} "gzip -l /tmp/${vmhost_name}.sql.gz | sed -n 2p | awk '{print \$2}'");
      if [ "$(./bin/docker-exec ${db_host} "whereis pv | sed 's/^pv:\s*//'")" != "" ]; then
        ./bin/docker-exec ${db_host} "zcat /tmp/${vmhost_name}.sql.gz | pv --force --progress --size ${UNPACKED_SIZE} | mysql --binary-mode --force -h 127.0.0.1 -u${db_user} -p${db_password} ${db_name}"
      else
        ./bin/docker-exec ${db_host} "zcat /tmp/${vmhost_name}.sql.gz | mysql --force -h 127.0.0.1 -u${db_user} -p${db_password} ${db_name}"
      fi
    else
      echo_error "Database backup not found at ./db_dumps/${vmhost_name}.sql.gz";
      exit 1;
    fi
}

##########################################
# Composer config
# Makes sure required configuration is set
##########################################
composer_config () {
  echo_info "Configuring Composer"...;
# commented for now as this caused issues.
#  if [ "$(./bin/docker-exec ${php_host} "composer1 config -g github-oauth.github.com 2>/dev/null | wc -l")" -eq "0" ]; then
#      if [ "${GITHUB_TOKEN}" = "12345" ]; then
#        echo_error "Github personal access token needs defining as GITHUB_TOKEN in file '.env'. The token added needs public_repo access as a mininimum.\n(see https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)";
#        exit 1;
#      fi
#
#      echo_info "Adding Github oauth token for composer1";
#      ./bin/docker-exec ${php_host} "composer1 config -g github-oauth.github.com ${GITHUB_TOKEN}";
#  fi
#
#  if [ "$(./bin/docker-exec ${php_host} "composer2 config -g github-oauth.github.com 2>/dev/null | wc -l")" -eq "0" ]; then
#      echo_info "Adding Github oauth token for composer2";
#      ./bin/docker-exec ${php_host} "composer2 config -g github-oauth.github.com ${GITHUB_TOKEN}";
#  fi
}

#############################
# Composer with any arguments
#############################
composer () {
      echo_info "Running composer ${*} ... ";
      ./bin/docker-exec ${php_host} "cd /var/www/htdocs/${vmhost_name}/;  ${COMPOSER_COMMAND} ${*}"
}

####################################
# Composer update
# where we don't have access to all
# repositories.
#
# Optional function parameter :
#   package(s) to update
#
# Required variables:
#    $vmhost_name
#    $php_host
####################################
composer_update () {
    # Phase ths step should run at.
    if [ $START_PHASE -ne 1 ] && [ $START_PHASE -ne 3 ]; then
        echo_info "[!!] Skipping composer update ...";
        return;
    fi

    echo_info "Running composer update ${*}...";
    ./bin/docker-exec ${php_host} "cd /var/www/htdocs/${vmhost_name}/; ${COMPOSER_COMMAND} update ${*}"
}

####################################
# Composer install
#
# Required variables:
#    $vmhost_name
#    $php_host
####################################
composer_install () {
    # Phase ths step should run at.
    if [ $START_PHASE -ne 1 ] && [ $START_PHASE -ne 3 ]; then
        echo_info "[!!] Skipping composer install ...";
        return;
    fi

    echo_info "Removing current vendor folder ...";
    ./bin/docker-exec ${php_host} "cd /var/www/htdocs/${vmhost_name}/; rm -rf ./vendor/*";
    echo_info "Running composer install ...";
    ./bin/docker-exec ${php_host} "cd /var/www/htdocs/${vmhost_name}/; ${COMPOSER_COMMAND} install --ignore-platform-reqs ${*}"
    status=$?
    if test $status -eq 0; then
      HAS_ECE_PATCHES=$(./bin/docker-exec ${php_host} "ls -l /var/www/htdocs/${vmhost_name}/vendor/bin/ | grep -e '^ece-patches$' | wc -l");
      if [ "$HAS_ECE_PATCHES" == "1" ]; then
      echo_info "File ece-patches Exist in the vendors, applying the patches";
      ./bin/docker-exec ${php_host} "cd /var/www/htdocs/${vmhost_name}/; php ./vendor/bin/ece-patches apply";
      fi
    fi
}

#############################################
# Display instructions for adding host entry.
#
# Required variables:
#     $vmhost_name
#############################################
host_entry_display () {
    # Phase ths step should run at.
    if [ ${START_PHASE} -gt 3 ] ; then
        return;
    fi

    echo -e "
${YELLOW}
####################################
# Please add host entry
#
# MAC/LINUX:
# 127.0.0.1 ${vmhost_name}
#
# WINDOWS:
# 192.168.99.100 ${vmhost_name}
####################################${NC}\n";
}

redis:flush(){
      echo_info "Flushing redis cache";
      ./bin/redis-flush "$1"
}

