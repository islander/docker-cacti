# docker-cacti

Docker container for [cacti 1.2.7][3] based on [QuantumObject/docker-cacti][5], reworked for using external MySQL through environment variables.

"Cacti is a complete network graphing solution designed to harness the power of [RRDTool's][6] data storage and graphing functionality. Cacti provides a fast poller, advanced graph templating, multiple data acquisition methods, and user management features out of the box. All of this is wrapped in an intuitive, easy to use interface that makes sense for LAN-sized installations up to complex networks with hundreds of devices."

## Install dependencies

  - [Docker][2]

To install docker in Ubuntu 18.04 use the commands:

    $ sudo apt-get update
    $ sudo wget -qO- https://get.docker.com/ | sh

 To install docker in other operating systems check [docker online documentation][4]

## Usage

To run container use the command below:

    docker run -d -p 80 -e MYSQL_ENV_HOST=db.example.com -e MYSQL_ENV_USER_PASSWD=cactiuserpasswd kiba/docker-cacti

Or with next compose file:

    $ cat docker-compose.yml
    ---
    version: '3'
    
    services:
      cactiweb:
        image: kiba/docker-cacti:latest
        depends_on:
          - cactidb
        ports:
          - "8080:80"
          - "161:161"
        environment:
          - TZ=Asia/Sakhalin
          - MYSQL_ENV_HOST=cactidb
          - MYSQL_ENV_DBNAME=cacti
          - MYSQL_ENV_USER=cacti
          - MYSQL_ENV_USER_PASSWD=cactiuserpasswd
          - MYSQL_ENV_ROOT_PASSWD=cactipasswd
        volumes:
          - /etc/localtime:/etc/localtime:ro
          - /opt/cacti/plugins/:/opt/cacti/plugins/
          - /opt/cacti/templates:/opt/cacti/templates/
      cactidb:
        image: mysql:5.7
        environment:
          - MYSQL_ROOT_PASSWORD=cactipasswd
        restart: always
        volumes:
          - /etc/localtime:/etc/localtime:ro
          - /opt/db_data:/var/lib/mysql

** -p 161:161  ==> remove to make sure you can monitor container and server running the container , this second more important to be able to monitoring all network interface of the server.

## Set the timezone per environment variable:

    -e TZ=Europe/London
  
or in yml:

    environment:
     - TZ=Europe/London
   
Default value is Asia/Sakhalin .

## Accessing the Cacti applications:

After that check with your browser at addresses plus the port assigined by docker:

  - **http://host_ip:port/cacti/**

Them you can log-in admin/admin, Please change the password and when installing double check the path to Spine binary that suppose to be /usr/local/spine/bin/spine. 

## Configuring Spine :

Go to Configuration -> Settings and click on the Paths tab.

Under the Alternate Poller Path, set the following:


    Spine Binary File Location = /usr/local/spine/bin/spine
    Spine Config File Path = /usr/local/spine/etc/spine.conf

Click Save at the bottom right.

Last is to make spine the active poller. Switch to the Poller tab and click on the drop down menu for Poller Type.Select spine and click save in the bottom right.


## To install plugins on cacti :

To access the container from the server that the container is running

     $ docker exec -it container_id /bin/bash

change directory to plugins directory of the cacti  

     $ cd /opt/cacti/plugins/

download and unpack plugins

     $ wget https://github.com/Cacti/plugin_flowview/archive/develop.zip
     $ unzip develop.zip
     $ mkdir -p /var/netflow/flows/completed
     $ chmod 777 /var/netflow/flows/completed

and them access to cacti console/plugin management and install it and enable it. This is only for an example, to install and configured flowview you need to check its documentation.  [https://github.com/Cacti/plugin_flowview/blob/develop/README.md][8]

## To initialize cacti database

Recommended MySQL settings:

    $ cat /etc/my.cnf
    [mysqld]
    max_heap_table_size = 1073741824
    max_allowed_packet = 16777216
    tmp_table_size = 256M
    join_buffer_size = 320M
    innodb_file_format=Barracuda
    innodb_large_prefix=1
    innodb_io_capacity=5000
    innodb_buffer_pool_instances=33
    innodb_buffer_pool_size = 4294967296
    innodb_doublewrite = ON
    innodb_flush_log_at_timeout = 10
    innodb_read_io_threads = 32
    innodb_write_io_threads = 16
    innodb_additional_mem_pool_size = 80M
    collation-server = utf8mb4_unicode_ci
    character-set-server = utf8mb4

## More Info

About Cacti [www.cacti.net][1]

To help improve this container [quantumobject/docker-cacti][5]

For additional info about us and our projects check our site [www.quantumobject.org][7]

[1]:http://www.cacti.net/
[2]:https://www.docker.com
[3]:http://www.cacti.net/
[4]:http://docs.docker.com
[5]:https://github.com/QuantumObject/docker-cacti
[6]:http://oss.oetiker.ch/rrdtool
[7]:https://www.quantumobject.org/
[8]:https://github.com/Cacti/plugin_flowview/blob/develop/README.md
