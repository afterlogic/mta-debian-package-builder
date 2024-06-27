#!/bin/sh
PERCENT=$1
USER=$2

YYYYMMDD=`date +%Y-%m-%d`

if [ $PERCENT -eq 100 ]; then
cat << EOF | /opt/afterlogic/libexec/dovecot/dovecot-lda -d $USER -o "plugin/quota=maildir:User quota:noenforcing"
Content-Type: text/plain; charset="UTF-8"
From: postmaster@domain.com
Subject: " Your $USER mailbox is over quota. "

Your mailbox is now $PERCENT% full.

This message was created automatically by mail delivery software at $USER.

The size of your mailbox has EXCEEDED the mailbox quota size set by the System 
Administrator. New e-mails are no longer delivered to your mailbox.

To avoid rejection of incoming mail, please remove some e-mails from your 
mailbox, or contact your System Administrator to increase quota value for your 
mailbox. 

* message sent on $YYYYMMDD 
* $USER
EOF
else
cat << EOF | /opt/afterlogic/libexec/dovecot/dovecot-lda -d $USER -o "plugin/quota=maildir:User quota:noenforcing"
Content-Type: text/plain; charset="UTF-8"
From: postmaster@domain.com
Subject: " Your mailbox is now $PERCENT% full. "

Your mailbox is now $PERCENT% full.

This message was generated automatically by email delivery software for $USER email account.

Your mailbox size is about to exceed account quota set by administrator.
When it's 100% full you will no longer be able to accept incoming mail.

To make sure your email account can accept mail, we recommend to remove a part of email messages
from the account or ask the administrator to increase storage quota set for the account.

* message sent on $YYYYMMDD 
* $USER
EOF
fi
