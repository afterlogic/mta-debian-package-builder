#!/bin/bash
exec /usr/lib/dovecot/dovecot-lda -d "${LOCAL_PART}@${DOMAIN}" -f "${SENDER}"
