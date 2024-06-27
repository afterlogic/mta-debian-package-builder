#!/bin/bash 
#
# fetch external mailboxes
#


# number of parallel fetching processes
jobs=1
g_interval="10"
# user mailbox, if any
#USER="denis2@afterlogic.com"

USER=$1

#f [ "$*" != "" ]; then
#   if [ "$1" == "-j" ]; then
#shift
#jobs=$1
#shift
#   fi
#
#   USER=$1
#i

# mailsuite dir
BASEDIR="/opt/afterlogic"

# fetcher path
MPOP="${BASEDIR}/bin/mpop"

# Dovecot's LDA
#LDA="${BASEDIR}/libexec/dovecot/dovecot-lda"
LDA="${BASEDIR}/scripts/dovecot-lda-wrapper.sh"

# database connect parameters
#db="afterlogic"
db="p7"
login="root"
pwd="mailbundle"
sock="${BASEDIR}/tmp/mysql.sock"

# log file
log="${BASEDIR}/var/log/fetcher/on_create_fetch-`date +%Y-%m-%d`.log"

# 30 minutes timeout (max time for mailbox locks)
let "timeout=1"

sql_run() {
    sql=$1
    row=`${BASEDIR}/usr/bin/mysql -u$login -p$pwd --sock=$sock -D $db -e "$sql"`
}

# is mailbox locked?
getlockstatus() {
    id_fetcher=$1
    sql="SELECT DISTINCT locked FROM awm_fetchers WHERE id_fetcher = '${id_fetcher}';"
#    echo "[SQL] > ${sql}" >>$log
    row=`${BASEDIR}/usr/bin/mysql -u$login -p$pwd --sock=$sock -D $db -e "${sql}"`
#    echo "[SQL1] < ${row}" >>$log
    echo $row | awk '{print $2}'
}

# lock mailbox
lock() {
    id_fetcher=$2
    sql_run "UPDATE awm_fetchers SET locked = 1 WHERE id_fetcher = '${id_fetcher}';"
}

# unlock mailbox
unlock() {
    id_fetcher=$2
    sql_run "UPDATE awm_fetchers SET locked = 0 WHERE id_fetcher='${id_fetcher}';"
}

# get mailbox last update time
gettimestamp() {
    id_fetcher=$2
    sql="SELECT DISTINCT mail_check_lasttime FROM awm_fetchers WHERE id_fetcher = '${id_fetcher}';"
    row=`${BASEDIR}/usr/bin/mysql -u$login -p$pwd --sock=$sock -D $db -e "${sql}"`
    echo $row | awk '{print $2}'
}

# set mailbox last update time
settimestamp() {
    id_fetcher=$2
    now=$2
    sql_run "UPDATE awm_fetchers SET mail_check_lasttime = '${now}' WHERE id_fetcher = '${id_fetcher}';"
}

# get messages and disk space usage by new messages
getusage() {
    dir=$1
    now=$2
    ( ls -la --full-time --time-style=+%s $dir/cur && \
      ls -la --full-time --time-style=+%s $dir/new )  \
    | awk -v now=${now} '
    BEGIN {
	messages = 0
	bytes = 0
    }
    /^-r/ {
	# file time
	time = $6
	# if file is newer than fetching start time
	if (time >= now) {
	    messages++
	    bytes += $5
	}
    }
    END {
	printf "0 %u %u\n", bytes, messages
    }'
}

escapetrans() {
    echo $1 | sed -e 's/\./\\2e/g' | sed -e 's/\//./g'
}

# fetch mail for one external mailbox
fetchmail() {
    # debug on/off
    debug="" # "-d"

# id_fetcher, inc_login, mail_check_interval, inc_host, inc_port, inc_login, inc_password, 
# dest_folder, inc_security, leave_messages, owner_login

    id_fetcher="${1}"
    user_local="${11}"

    interval="${3}"

    # get path to local maildir
    local_part=`echo $user_local | awk -F@ '{print $1}'`
    domain=`echo $user_local | awk -F@ '{print $2}'`
    maildir="${BASEDIR}/data/${domain}/${local_part}"
    # fts indexer lock file
    lockfile="${maildir}/reindex.lck"

    # get params
    host="${4}"
    port="${5}"
    username="${6}"
    passwd="${7}"
    imap_folder="${8}"
    inc_security="${9}"
    leave_messages="${10}"

    # convert filesystem folder name to IMAP one:
    # change escapes to corresponding chars

    local_folder=`escapetrans ${imap_folder}`

    mailbox="${maildir}/.${local_folder}"
    uidlfile="${maildir}/fetcher-id${id_fetcher}-uidls"
    fetchlog="${log}"

    # create dirs and set permissions
    for d in "" "/tmp" "/cur" "/new"; do
	if [ ! -d "${mailbox}${d}" ]; then
	    mkdir -p "${mailbox}${d}"
	    chmod 770 "${mailbox}${d}"
	    chown afterlogic:afterlogic "${mailbox}${d}"
	fi
    done

    echo "[`date +%T`] <fetchmail> ${host}:${port}/${username} > ${domain}/${local_part}/${local_folder}" >>$fetchlog

    status=`getlockstatus $id_fetcher`

    if [ "$status" == "1" ]; then
	# get timestamp
	timestamp=`gettimestamp $id_fetcher`
	# get current time
	now=`date +%s`
	# time left
	let "timeleft=now-timestamp"
	#
	if [ "$timeleft" -ge "$timeout" ]; then
	    echo "[INFO] Previous lock timeout expired, acquiring the lock..." >>$fetchlog
	    unlock $id_fetcher
	    settimestamp $id_fetcher $now
	else
	    echo "[INFO] The fetching process for a current mailbox is already running, exiting..." >>$fetchlog
	    echo "[`date +%T`] </fetchmani>" >>$fetchlog
	    return
	fi
    else
	# create lock
	echo "[INFO] Mailbox is free, locking it..." >>$fetchlog
	lock $id_fetcher
	settimestamp $id_fetcher $now
    fi

    case "$inc_security" in
    '1')
	tls="on"
	starttls="off"
    ;;
    
    '2')
	tls="on"
	starttls="on"
    ;;

    *)
	tls="off"
	starttls="off"
    esac

    case "$leave_messages" in
    '0')
	keep="off"
    ;;

    *)
	keep="on"
    esac

    # execute a fetch command as user afterlogic 
    su -s /bin/bash -m -c "${MPOP} --host=\"${host}\" --port=${port} --user=\"${username}\" --auth=user \
	--uidls-file=\"${uidlfile}\" --delivery=mda,\"${LDA} -d ${user_local} -m '${imap_folder}'\" \
	--keep=${keep} --only-new=on --tls=${tls} --tls-certcheck=off --tls-starttls=${starttls} --received-header=off \
	--half-quiet ${debug} --passwordeval=\"echo ${passwd}\"" afterlogic >>$fetchlog

    echo $user_local `getusage $mailbox $now`

    # change mailbox permissions to mode 640, user afterlogic:afterlogic
    # a problem: we need to run this script as root, else some files (like /dev/stdout)
    # are inaccessible by user afterlogic. Additionally, mpop creates files with mode 600
    for d in "/cur" "/new" "/tmp"; do
	chmod 660 "${mailbox}${d}"/* >/dev/null 2>&1
	chown afterlogic:afterlogic "${mailbox}${d}"/* >/dev/null 2>&1
    done

    # unlock
    echo "[INFO] Unlock mailbox..." >>$fetchlog
    unlock $id_fetcher

    # do incremental reindexing 
    # when the mail arrived
    # ./dovecot-fts-reindex.sh ${USER}

    echo "[`date +%T`] </fetchmani>" >>$fetchlog
}

# process external mailboxes one by one
# according the settings passed via stdin
processmboxes() {
    i=0
    while read line; do
	if [ "$i" == "0" ]; then
	    # skip the first line (containing column names)
	    i=1
	else
	    # get current unixtime
	    now=`date +%s`
	    id_fetcher=`echo $line | awk '{print $1}'`
	    inc_security=`echo $line | awk '{print $2}'`
	    inc_host=`echo $line | awk '{print $3}'`
	    inc_port=`echo $line | awk '{print $4}'`
	    inc_login=`echo $line | awk '{print $5}'`
	    inc_password=`echo $line | awk '{print $6}'`
	    enabled=`echo $line | awk '{print $7}'`
	    locked=`echo $line | awk '{print $8}'`
	    leave_messages=`echo $line | awk '{print $9}'`
	    dest_folder=`echo $line | awk '{print $10}'`
	    mail_check_interval=`echo $line | awk '{print $11}'`
	    mail_check_lasttime=`echo $line | awk '{print $12}'`
	    owner_login=`echo $line | awk '{print $13}'`
	
	    mail_check_interval="${g_interval}"
	
	    # time left
	    let "timeleft=now-mail_check_lasttime"
	    echo "[INFO] ${owner_login}/${inc_login} - left ${timeleft}s | ${mail_check_interval}s" >>$log
	
	    if [ "$timeleft" -ge "$mail_check_interval" ]; then
		# if the following signals are caught, then unlock and exit
		trap "{ unlock $id_fetcher; exit 1; }" SIGINT SIGKILL SIGTERM

		# start mail fetching
		fetchmail $id_fetcher $inc_login $mail_check_interval $inc_host $inc_port $inc_login $inc_password $dest_folder $inc_security $leave_messages $owner_login
		
	    else
		echo "[SKIP] Mail check time not reached, skipping the fetch..." >>$log
	    fi
	fi
	echo "--- --- --- --- --- ---" >>$log
    done
}

# a single fetching job
job() {
    # get the list of external pop3 mailboxes settings
    # and fetch each one

    ${BASEDIR}/usr/bin/mysql -u$login -p$pwd --sock=$sock $db -e \
	"SELECT DISTINCT \
		id_fetcher, inc_security, inc_host, inc_port, inc_login, inc_password, \
		enabled, locked, leave_messages, dest_folder, \
		mail_check_interval, mail_check_lasttime, \
		acct.mail_inc_login AS owner_login \
	FROM \
		awm_fetchers \
	INNER JOIN \
		awm_accounts AS acct ON awm_fetchers.id_acct = acct.id_acct \
	WHERE \
		acct.deleted = 0 AND enabled = 1 $constraint \
	ORDER BY mail_check_lasttime DESC;" \
	    | processmboxes
}

# if user is specified
constraint=""
if [ "$USER" != "" ]; then
    constraint="AND acct.mail_inc_login = '${USER}'"
fi

# start a number of parallel fetch processes
while [ "$jobs" -gt "0" ]; do
    ( echo "*** === `date +%T` === ===" >>$log;
      echo "[RUN] Invoked: $0 $*" >>$log;
      job;
      echo "*** === `date +%T` === ***" >>$log ) &
    let "jobs=jobs-1"
done
