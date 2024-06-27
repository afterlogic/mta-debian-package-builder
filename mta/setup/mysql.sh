#!/bin/bash
MYSQL_CONF="/etc/mysql/debian.cnf"

parse_mysql_config() {
    local RES=`cat $MYSQL_CONF | grep -m 1 "^\s*$1\s*=" | sed 's/^.*=\s*\"\?\([^\"]*\)\"\?/\1/g'`
    echo $RES
}

DB_NAME="afterlogic"
DB_USER="afterlogic"
DB_PASS=`perl -le'print map+(A..Z,a..z,0..9)[rand 62],0..7'`

MYSQL_USER=$(parse_mysql_config user)
MYSQL_PASS=$(parse_mysql_config password)

SQL_CREATE_DATABASE="CREATE DATABASE $DB_NAME;"
SQL_DROP_USER_STATEMENT="DROP USER '$DB_USER'@'localhost';"
SQL_USER_STATEMENT="CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';GRANT SELECT,ALTER,INSERT,UPDATE,DELETE,CREATE,DROP,INDEX,REFERENCES ON \`$DB_NAME\` . * TO '$DB_USER'@'localhost';FLUSH PRIVILEGES;"
SQL_PASS_STATEMENT="SET PASSWORD FOR '$DB_USER'@'localhost' = PASSWORD( '$DB_PASS' );FLUSH PRIVILEGES;"

if [ "$MYSQL_PASS" = "" ]; then
    MYSQLRUN="mysql -u$MYSQL_USER"
else
    MYSQLRUN="mysql -u$MYSQL_USER -p$MYSQL_PASS"
fi

echo "$SQL_CREATE_DATABASE" | $MYSQLRUN 2>/dev/null
echo "$SQL_DROP_USER_STATEMENT" | $MYSQLRUN 2>/dev/null
echo "$SQL_USER_STATEMENT" | $MYSQLRUN

sudo -u afterlogic php /opt/afterlogic/setup/afterlogic.php install $DB_NAME $DB_USER $DB_PASS

/bin/bash /opt/afterlogic/setup/config.sh $DB_PASS
