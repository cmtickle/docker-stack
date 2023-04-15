#!/usr/bin/env bash

# Make ssh key permissions correct
chmod 700 .ssh/*

if [ ! -d "db_dumps" ]; then
	echo "Creating db_dumps directory";
	mkdir db_dumps;
fi

#############################################
# PROJECT VARIABLES
# OVERRIDE THESE IN SETUP SCRIPTS AS REQUIRED
#############################################
repo_type='github'; # 'github', 'bitbucket' or 'custom'
cvs_custom_url='';  # Only used for custom repo type as above
cvs_organisation='cmtickle'; # The organisation name for Github or Bitbucket
cvs_branch="develop"; # The branch which will be cloned during setup.
project_name='magento2'; # Name as used in Github or Bitbucket
resources_storage='local'; # Where to access shared resources (see README.md), 'local' or 's3'
s3_bucket="docker-stack"; # Bucket to download resources from in s3.
db_host='mysql57'; # 'percona56' or 'percona57'
php_host='php74'; # 'php56', 'php70', 'php71', 'php72', 'php73' or 'php74'
required_containers=("nginx", "${php_host}" "${db_host}");
composer_version="1"; # 1 = 1.10 or 2 = 2.1
db_name=''; # Unique name for project database
db_file='db.sql.gz'; # default file name for database to import.
db_user='root'; # Username for database connection
db_password='root'; # Password for database connection.
vmhost_name=''; # domain name for this project in local vm. MUST contain 'm1' for M1 hosts or 'm2' for M2 hosts
github_args='';
bitbucket_args='';
docker_compose_args=''; # Project specific docker-compose arguments e.g. "-f my-custom.yml"

