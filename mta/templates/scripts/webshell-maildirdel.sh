#!/bin/bash
##
# Afterlogic Mailsuite
# script deletes user's home maildir
# (c) Afterlogic Corp. 2009-2014
##

# TODO, review if 'strict' error mode is needed
set -e
MAIL_HOME="/opt/afterlogic/data"
LOG_FILE=/opt/afterlogic/var/log/maildirdel-`date +%Y-%m-%d`.txt

log () {
	# check if current script has permissions to write to $LOG_FILE
	if touch "$LOG_FILE" &>/dev/null; then
		echo `date` $1 >> $LOG_FILE
	fi
}

log " [DEL] ('${2}@${1}'): Domain: $1 User: $2"

if [ -d "${MAIL_HOME}/$1/$2" ]
then
	/bin/rm -rf "${MAIL_HOME}/$1/$2"
	log " [MAILDIR DELETED] ('${2}@${1}'): '${MAIL_HOME}/${1}/${2}'"
fi

