#!/bin/bash
# Move this script to "/etc/cron.hourly".

DESTPATH="/usr/share/nginx/html/mirrors"
RSYNC=/usr/bin/rsync
LOCKFILE=/tmp/rsync-mirrors.lock

synchronize() {
    echo "Toasted Mirrors: Manjaro sync"
    $RSYNC -rtlvH --delete-after --delay-updates --safe-links rsync://ftp.tsukuba.wide.ad.jp/manjaro/ "$DESTPATH/manjaro"

    echo "Toasted Mirrors: Ubuntu-ports sync"
    $RSYNC -rtlvH --delete-after --delay-updates --safe-links rsync://ports.ubuntu.com/ubuntu-ports/  "$DESTPATH/ubuntu-ports"
}

if [ ! -e "$LOCKFILE" ]
then
    echo $$ >"$LOCKFILE"
    synchronize
else
    PID=$(cat "$LOCKFILE")
    if kill -0 "$PID" >&/dev/null
    then
        echo "Rsync - Synchronization still running"
        exit 0
    else
        echo $$ >"$LOCKFILE"
        echo "Warning: previous synchronization appears not to have finished correctly"
        synchronize
    fi
fi
