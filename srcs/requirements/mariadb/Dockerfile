# Base image
FROM debian:latest

# Update the package repository and install MariaDB and dumb-init
RUN		apt-get update -y && apt-get upgrade -y && \
		apt-get install -y mariadb-server dumb-init

RUN		chmod +x /usr/bin/dumb-init && \
        mkdir -p /var/run/mysqld && \
		chown -R mysql:mysql /var/run/mysqld && \
		chmod 777 /var/run/mysqld


RUN     mkdir -p /tmp/mariadb/conf/ && \
        mkdir -p /tmp/mariadb/tools/

COPY    ./tools/mariadb.sh /tmp/mariadb/tools/mariadb.sh
COPY    ./conf/setup.sql /tmp/mariadb/conf/setup.sql

RUN     chmod 777 /tmp/mariadb/tools/mariadb.sh && \
        chmod 777 /tmp/mariadb/conf/setup.sql

# Expose port 3306 for MySQL traffic
EXPOSE  3306

ENTRYPOINT	["/usr/bin/dumb-init", "--", "bash", "/tmp/mariadb/tools/mariadb.sh"]

# Start MariaDB service
CMD ["mysqld"]
