#!/bin/bash -x

BASEDIR="/opt/afterlogic"

cd /opt/afterlogic/data

for d in `find * -maxdepth 0 -type d ! -name root`
        do cd $d
echo        for u in `find * -maxdepth 0 -type d`
        do
echo        $BASEDIR/bin/doveadm fts rescan -u $u@$d
###        $BASEDIR/bin/doveadm index -u $u@$d INBOX
        done
    done
exit 0
