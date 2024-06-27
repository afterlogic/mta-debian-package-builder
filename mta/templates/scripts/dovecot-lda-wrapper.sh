#! /bin/sh
#
# dovecot lda wrapper
#

BASEDIR="/opt/afterlogic"
USER=""
CMDLINE=$*

mbox=""

# extract user and mailbox name from the command line
d=0
m=0
for w in $*; do
    if [ "$d" == "1" ]; then
	USER=$w
	d=0
    fi
    if [ "$m" == "1" ]; then
	mbox=$w
	m=0
    fi
    case "$w" in
    -d)
	d=1
	continue
    ;;
    -m)
	m=1
	continue
    ;;
    esac
done

if [ "${mbox}" == "" ]; then
    mbox="INBOX"
fi

local_part=`echo $USER | awk -F@ '{print $1}'`
domain=`echo $USER | awk -F@ '{print $2}'`

maildir="${BASEDIR}/data/${domain}/${local_part}"

/usr/lib/dovecot/dovecot-lda ${CMDLINE}

rc=$?

# do incremental reindexing 
# when the mail arrived

exit $rc
