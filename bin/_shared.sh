#!/usr/bin/env bash

######################################################
# THIS IS A PLACE FOR CODE SHARED ACROSS /bin SCRIPTS.
#
# BY INCLUDING IT IN ALL /bin SCRIPTS WE ALSO ENSURE
# THAT WE RUN THE SCRIPTS FROM THE ROOT OF THE DOCKER
# FOLDER.
######################################################


bash_version=${BASH_VERSION}
bash_version=$(echo ${bash_version//[!0-9.]/} | xargs printf "%.2f" 2>/dev/null);
bash_version=${bash_version/,/.};
if (( $(echo "${bash_version} < 4.30" | bc -l) )); then
  echo "Bash version 4.3-alpha or later is required.";
  exit 1;
fi

PLATFORM=$(uname)
OS=$(uname)_$(uname -m);

# DECLARE REQUIREMENTS FOR SUPPORTED OPERATING SYSTEMS
Linux_x86_64_REQUIREMENTS=("git" "docker-compose" "docker" "s3cmd");
Linux_aarch64_REQUIREMENTS=("git" "docker-compose" "docker" "s3cmd");
Darwin_x86_64_REQUIREMENTS=("git" "docker-compose" "docker" "s3cmd");
Darwin_arm64_REQUIREMENTS=("git" "docker-compose" "docker" "s3cmd");
# ASSIGN REQUIREMENTS FOR THIS OPERATING SYSTEM
declare -n PLATFORM_REQUIREMENTS="${OS}_REQUIREMENTS"
if [ -z ${PLATFORM_REQUIREMENTS} ]; then
    echo "ERROR: Unsupported/untested operating system $OS." >&2
    exit 1
fi

# Ignore requirements if we're inside a docker-stack container;
if [[ "$PWD" == *"htdocs"* ]]; then
  PLATFORM_REQUIREMENTS=();
fi

# CHECK THE REQUIREMENTS
MISSING_REQUIREMENTS=0;
for requirement in "${PLATFORM_REQUIREMENTS[@]}"
do
   if ! [ -x "$(command -v $requirement)" ]; then
     echo "ERROR : Required command \"$requirement\" is not installed." >&2
     MISSING_REQUIREMENTS=$((MISSING_REQUIREMENTS+1))
   fi
done
if [ "$MISSING_REQUIREMENTS" -gt 0 ]; then
  echo "PLEASE RESOLVE MISSING REQUIREMENTS BEFORE RUNNING THIS COMMAND AGAIN" >&2
  exit 1;
fi

internal_set_USER_by_CONTAINER () {
  if [ -z ${CONTAINER+x} ]; then
    echo 'ERROR: $CONTAINER is unset';
    exit 1;
  fi

  if [[ "$CONTAINER" == *"php"* ]] || [[ "$CONTAINER" == *"magento"* ]]; then
    USER="www-data"
  elif [[ "$CONTAINER" == *"nginx"* ]]; then
    USER="nginx"
  elif [[ "$CONTAINER" == *"mysql"* ]]; then
    USER="mysql"
  elif [[ "$CONTAINER" == *"redis"* ]]; then
    USER="redis"
  else
    echo "ERROR : Unsupported container $CONTAINER";
    exit 1;
  fi
}


