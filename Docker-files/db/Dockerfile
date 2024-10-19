FROM mysql:8.0.33
LABEL "project"="vprofile"
LABEL "Author"="Shihab"

ENV MYSQL_ROOT_PASSWORD="vprodbpass"
ENV MYSQL_DATABASE="accounts"

ADD db_backup.sql docker-entrypoint-iniotdb.d/db_backup.sql