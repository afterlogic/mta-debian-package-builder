#! /bin/sh
#
# Dovecot post-login script
#

BASEDIR="/opt/afterlogic"

#echo "--- `date +%T` --- ${USER} logged in" >>$BASEDIR/scripts/imap.txt

local_part=`echo $USER | awk -F@ '{print $1}'`
domain=`echo $USER | awk -F@ '{print $2}'`

domaindir="${BASEDIR}/data/${domain}"
maildir="${BASEDIR}/data/${domain}/${local_part}"
subscriptions="${maildir}/subscriptions"

mkfldr() {
    dir="$1"
    if [ ! -d "${dir}" ]; then
	for d in "" "/tmp" "/cur" "/new"; do
	    mkdir -p "${dir}${d}"
	    chown afterlogic.afterlogic "${dir}${d}"
	    chmod 770 "${dir}${d}"
	done
    fi
}

# create dirs and subscriptions
if [ ! -f "${subscriptions}" ]; then
    # create the maildir root directory
    if [ ! -d "${domaindir}" ]; then
	mkdir -p "${domaindir}"
	chown afterlogic.afterlogic "${domaindir}"
	chmod 770 "${domaindir}"
    fi

    # create subdirs
    if [ ! -d "${maildir}" ]; then
	for d in "" "/.Drafts" "/.Sent" "/.Spam" "/.Trash"; do
	    mkfldr "${maildir}${d}"
	done
    fi

    # create subscriptions file
    echo "Drafts"  >"$subscriptions"
    echo "Sent"   >>"$subscriptions"
    echo "Spam"   >>"$subscriptions"
    echo "Trash"  >>"$subscriptions"
    chown afterlogic.afterlogic "$subscriptions"
    chmod 660 "$subscriptions"

    # convert maildir from courier to dovecot format
    ${BASEDIR}/scripts/courier-dovecot-migrate.pl --quiet --to-dovecot --convert ${maildir}
fi

#if [ ! -d "${maildir}/lucene-indexes" ]; then
    # create lucene indexes subdir
#    mkdir -p "${maildir}/lucene-indexes"
#    chown afterlogic:afterlogic "${maildir}/lucene-indexes"
#    chmod 770 "${maildir}/lucene-indexes"
    # start fts indexing
#    ${BASEDIR}/bin/doveadm fts rescan -u ${USER} >\dev\null 2>&1
#fi

# update fts indexes (it is started from fetcher)
#${BASEDIR}/bin/doveadm index -u ${USER} '*' &

# migrate sieve filters
#${BASEDIR}/scripts/courier-dovecot-sieve.sh ${USER} >\dev\null 2>&1

# start fetcher for a given account
# ${BASEDIR}/scripts/mailfetch.sh -j 1 ${USER} >\dev\null 2>&1 &

exec "$@"
