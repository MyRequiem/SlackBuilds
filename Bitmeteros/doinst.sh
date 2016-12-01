#! /bin/bash

# create or upgrade database
DB_FILE=/var/lib/bitmeter/bitmeter.db

# if database already exist
if [ -f ${DB_FILE} ]; then
    rm -f ${DB_FILE}.new
    bmdb upgrade 7
else
    mv ${DB_FILE}.new ${DB_FILE}
fi

BTM=/etc/init.d/bitmeter
BTM_WEB=/etc/init.d/bitmeterweb

# start
${BTM} start
${BTM_WEB} start

# autostart
RC_LOCAL=/etc/rc.d/rc.local

if ! grep -q "${BTM} start" ${RC_LOCAL}; then
cat << EOF >> ${RC_LOCAL}
# Starting BitMeter Capture daemon: bmcapture
if [ -x ${BTM} ]; then
    ${BTM} start
fi

# Starting BitMeter Web Interface daemon: bmws
if [ -x ${BTM_WEB} ]; then
    ${BTM_WEB}  start
fi

EOF
fi

echo -e "Type in the browser: http://localhost:2605/index.html\n"
