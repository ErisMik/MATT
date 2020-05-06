#!/bin/bash
# Move this script to "/etc/cron.hourly".

DESTPATH="/usr/share/nginx/html/mirrors"
RSYNC=/usr/bin/rsync
LOCKFILE=/tmp/rsync-mirrors.lock

LOG_PREFIX="Toasted Mirrors:"

fixpermissions() {
    echo "$LOG_PREFIX Fix file permissions"

    find "$DESTPATH" -type d -exec chmod 775 {} \;
    find "$DESTPATH" -type f -exec chmod 644 {} \;
}

synchronize() {
    echo "$LOG_PREFIX Manjaro sync"
    $RSYNC -rtlvH --delete-after --delay-updates --safe-links rsync://ftp.tsukuba.wide.ad.jp/manjaro/ "$DESTPATH/manjaro"

    echo "$LOG_PREFIX Ubuntu-ports sync"
    $RSYNC -rtlvH --delete-after --delay-updates --safe-links \
           --exclude "*powerpc.deb" --exclude "*ppc64el.deb" --exclude "*s390x.deb" --exclude "*riscv64.deb" \
           --exclude "*powerpc.udeb" --exclude "*ppc64el.udeb" --exclude "*s390x.udeb" --exclude "*riscv64.udeb" \
           rsync://ports.ubuntu.com/ubuntu-ports/ "$DESTPATH/ubuntu-ports"

    # Only need to run these every few days, to reduce disk wear
    (( RANDOM % 48 == 0 )) && fixpermissions
}

if [ ! -e "$LOCKFILE" ]
then
    echo $$ >"$LOCKFILE"
    synchronize
else
    PID=$(cat "$LOCKFILE")
    if kill -0 "$PID" >&/dev/null
    then
        echo "$LOG_PREFIX Rsync - Synchronization still running"
        exit 0
    else
        echo $$ >"$LOCKFILE"
        echo "$LOG_PREFIX Warning: previous synchronization appears not to have finished correctly"
        synchronize
    fi
fi
