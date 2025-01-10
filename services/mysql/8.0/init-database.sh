#!/bin/bash
set -e

echo "MySQL is ready. Running initialization scripts..."
for file in /docker-entrypoint-initdb.d/*.sql
do
    echo "Executing $file..."
    mysql --defaults-file=/tmp/mysql.cnf "$MYSQL_DATABASE" < "$file"
done

echo "Initialization complete."
