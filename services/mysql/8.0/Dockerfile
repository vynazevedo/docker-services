FROM mysql:8.0

ARG MYSQL_DATABASE
ARG MYSQL_USER
ARG MYSQL_PASSWORD

ENV MYSQL_DATABASE=${MYSQL_DATABASE}
ENV MYSQL_USER=${MYSQL_USER}
ENV MYSQL_PASSWORD=${MYSQL_PASSWORD}
ENV MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}

ENV TIME_ZONE="America/Sao_Paulo" \
    TZ="America/Sao_Paulo" \
    ACCEPT_EULA=Y \
    DEBIAN_FRONTEND=noninteractive

COPY ./environment/mysql/docker-entrypoint-initdb.d/ /docker-entrypoint-initdb.d/

RUN chmod -R 755 /docker-entrypoint-initdb.d/

COPY ./environment/mysql/init-database.sh /docker-entrypoint-initdb.d/

CMD ["mysqld"]