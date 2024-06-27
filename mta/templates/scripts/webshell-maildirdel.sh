#!/bin/bash
##
# Afterlogic Mailsuite
# script deletes user's home maildir
# (c) Afterlogic Corp. 2009-2014
##

set -e
mail_home="/opt/afterlogic/data"
LOG_FILE=/opt/afterlogic/var/log/maildirdel-`date +%Y-%m-%d`.txt

echo `date` " [DEL] ('${2}@${1}'): Domain: $1 User: $2" >> $LOG_FILE

if [ -d "${mail_home}/$1/$2" ]
then
	/bin/rm -rf "${mail_home}/$1/$2"
	echo `date` " [MAILDIR DELETED] ('${2}@${1}'): '${mail_home}/${1}/${2}'" >> $LOG_FILE
fi

