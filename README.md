# cmtickle/docker-stack
Dockerised system to run LEMP stack applications (primarily developed to run Magento 2).

This repository contains everything which should be needed to start developing on a Magento 2 project.

## TLDR; Quick Start
* Install requirements for [Linux](#linux-requirements) or [Mac](#mac-requirements)
* [Download and start the Docker stack](#download-and-start-the-docker-stack)
* [Install a project](#install-a-sample-m2-project)

### Download and start the Docker stack
Run the following commands (this assumes you're using Linux, PC needs a few changes making):
```bash
cd ~/
git clone git@github.com:cmtickle/docker-stack.git
cd docker-stack
```

### Build and start the required containers
```bash
./project/m2_opensource docker:build
./project/m2_opensource docker:start
```

### Install the sample Magento 2 Opensource project
```bash
./project/m2_opensource setup:all
```
You may see an error requiring you to add credentials to auth.json, follow the instructions.

Edit your hosts file per the message when this process completes.

**You should now have a working M2 opensource instance!!**



------

## How to use this repository.
* Clone the repository to your local machine.
* Install Docker - Follow instructions available from : https://docs.docker.com/install/
* Install Docker Compose - Follow instructions available from : https://docs.docker.com/compose/install/

### Linux Requirements
Ubuntu : Docker.io, Docker-compose, Git, s3cmd
```
sudo apt-get install docker.io docker-compose git s3cmd
```

### Mac Requirements
```bash
brew install bash
brew install mutagen-io/mutagen/mutagen-compose
brew install s3cmd
```

**NOTE:** Mutagen works well if you are running one or 2 projects. If you run more than this, performance will be affected.
To get around this, you can run this stack without file synchronisation (see "How to: run this stack without file synchronisation").


### Where is 'composer'?
The stack has both Composer 1 and Composer 2 installed.
Use `composer1` or `composer2` instead of `composer` inside the PHP containers.

**OPTIONAL : Centralised storage of databases and configuration:**

### AWS S3 - For Project Admins

If you have multiple people using this setup (e.g. a Dev team) and host your fork of this project in a __PRIVATE REPOSITORY__.
This setup will allow all team members to access a standardised database and configuration.

Create an S3 bucket (the name of this is referenced as 's3_bucket' variable in `./project/includes/_config.sh`). Default is 'docker-stack'.

For each Magento 2 project you need to upload to `s3://docker-stack/<$vmhost_name per project setup script>`:
* db.sql.gz = a 'full' database backup (I suggest you use n98-magerun2 and create the backup without customer data). This can optionally be overridden in the `db_name` variable in a project script.
* env.php = a fully completed env.php with correct dbhost etc.
* (optionally) config.php = a backup of the correct M2 config.php file, this may also be in the project repository.
* Either:
    * 'configurator' folder for CTI Digital Configurator (config will be applied if this is present).
    * dbconfig.sql.gz = a backup of the core_config_data table with the hostname changed to same as defined in $vmhost_name of setup script. See [project/resources/eg-m2-opensource.local/configurator](./project/resources/eg-m2-opensource.local/configurator) for an example.

Once everything is in S3, the project scripts will need editing to have `resources_storage='s3'`

### AWS S3 - User setup.
Use the IAM credentials supplied by whoever administers your AWS account.

Create a file at ~/.s3cfg with the following contents ([documentation of file contents](https://s3tools.org/kb/item14.htm))
```
[default]
access_key = AKIA3UZxxxxxxxxx
secret_key = MM/HmXWzxJAxxxxxxxxxxxxxxx
bucket_location = eu-west-2
```

Try the following to make sure you have access:
```bash
s3cmd ls s3://docker-stack
```

**All commands in this README should be executed from the base folder of your clone of this repository. For the sake of 
 this README we will use the example M2 Opensource project. If you add new projects, the process should be the same.**

## How to : Start a specific container in the foreground (to see logs if something isn't starting e.g. php74)
```bash
./bin/docker-compose up php74
```

## How to : Start the docker stack in the background (so you can close the terminal)
```bash
./project/m2_opensource docker:start
```

## How to : Check the docker containers are started.
```bash
./project/m2_opensource docker:status
(or)
./project/m2_opensource docker:status_all
```

## How to : Stop the docker containers.
```bash
./project/m2_opensource docker:stop
```

## How to : Update your Docker containers to reflect changes made in version control or Dockerfile:
```bash
(optionally) git pull
./project/m2_opensource docker:build
./project/m2_opensource docker:start
```
OR
```bash
./project/m2_opensource docker:refresh
```

## How to : Remove the containers (for example if they are somehow broken):
```bash
./bin/docker-compose stop
./bin/docker-compose rm -v
```

## How to : Remove everything including stored data (for example to switch between the volume synchronised and non-synchronised versions of this stack **DESTRUCTIVE**):
```bash
./bin/docker-compose down --volumes
./bin/docker-compose rm -v
```

## How to : Access the correct PHP container and folder for your project.
```bash
./project/m2_opensource access:php
```

## How to : change the version of PHP used by a project

* Edit the `$PHP_HOSTM2` map in `./docker/nginx/m-hosts.conf`.
* Change the `php_host` variable in `./projects/<your_project>`
* Run : `./project/<your_project> docker:refresh` or 
 `./bin/docker-compose build nginx && ./bin/docker-compose up -d nginx`

## How to : Access the correct MySQL container and database for your project from command line.
```bash
./project/m2_opensource access:mysql
```

### To connect to MySQL with a MySQL GUI Client.

You can use any MySQL client to connect to port 3307 (MySQL 5.7) or port 3308 (MySQL 8.0) of the Docker IP (127.0.0.1 for Mac/Linux, 192.168.99.100 for PC) using credentials from [.env](.env)

## How to : Access any container (optionally as a specific user)
```
# See the usage and available containers
./bin/docker-access
# Example to access PHP 7.4 container as the default user
./bin/docker-access php74
# Example to access PHP 7.4 container as root user
./bin/docker-access root php74
```

### How to : View email which has been sent from Magento.

One of the containers in this setup is Mailhog. All email has been redirected to this container to prevent accidental customer contact.

To start the container run `./project/mailhog docker:start`.
Mailhog can be viewed at [http://mailhog.local/](http://mailhog.local/) (if you add a local host entry per the project script) or [http://localhost:8025/](http://localhost:8025/) (Linux or Mac) or [http://192.168.99.100:8025/](http://192.168.99.100:8025/) on PC.
To stop the container run `./project/mailhog docker:stop`.

### How to add a new Magento project

Each project should have a script in the 'project' folder of this repository. Sample scripts are provided for Magento 2 Opensource and Commerce.

The `./project/m2_opensource` script is the most standard version. It's the easiest starting point for a new project.

The Magento scripts in `./project` will:
 * Clone the Github/Bitbucket repository into the docker stack.
 * Copy or download a backup of the magento database (recommended this is without sensitive data).
 * Load in the database backup.
 * Download a working env.php.
 * Run composer install.
 
When the script finishes you will be informed of an entry which you need to add to your local hosts file. Once you've added this entry you should be able to access the project using a web browser.

### How to: run this stack without file synchronisation.

If the performance of file/volume synchronisation is affecting your ability to use this stack (usually related to Mac and Mutagen), you can disable it.

Edit your `~/.bashrc` or `~/.zprofile` file and add: `export DOCKER_NOSYNC_VOLUMES=1`. Restart your terminal and check the variable is set by running `env | grep NOSYNC`.

You may have to destroy the docker volumes (documented elsewhere in this README) if you have already been running projects.

**NOTE:** Whilst this method gives a noticeable performance boost on some systems, the side effect is that project files are not available for editing locally.
To allowed for continued development, two commands are available in the project scripts 
e.g. `./project/m2_opensource IDE:vscode` will start an instance of vscode-server which has access to the project files. 
or `./project/m2_opensource IDE:phpstorm` will start an instance of PHPStorm remotely which has access to project files (PHPStorm local client is still required).


## How does all this work?

### [./docker/services.yml](services.yml)
Responsible for the basic configuration of each container.

for example :
```yaml
    php74:
      user: "${USERID}:${GROUPID}"
      build:
        context: ./docker/php/7.4
      volumes:
        - composer_cache:${HOME}/.composer/cache
        - ssh-key:/var/www/htdocs/.ssh
        - web_files:/var/www/htdocs
      environment:
        MYSQL_USER: ${MYSQL_USER}
        MYSQL_PASSWORD: ${MYSQL_PASSWORD}
        XDEBUG_MODE: ${XDEBUG_MODE}
```
This creates a container which will be referred to and accessible on the internal Docker network as "php74". 
The name which your host PC refers to the container as will be different and can be viewed by checking for running containers (command above).
A named volume 'composer_cache' is created so that data can persist between restarts/rebuild of the container and be shared between containers. 
The named volume is mounted to folder '/root/.composer/cache'.
The web_files mount/volume is mounted to '/var/www/htdocs' of the container.
Finally, some environment variables defined in file [./docker/.env](.env) of this repository are made available to the container.

### The Dockerfile
e.g. [docker/php/7.4/Dockerfile](docker/nginx/Dockerfile)

This file is referred to in the docker-compose.yml file and tells docker how to build the container. 
The first line of the file dictates the basse container to use (which will download from Docker Hub).
The remaining lines of the file can be used to add additional configuration files, set environment variables, add packages which are required to host your application etc.
