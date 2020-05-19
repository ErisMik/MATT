#!/bin/bash

DESTPATH=/usr/share/nginx/html/mirrors
LOCKFILE=/tmp/rsync-mirrors.lock

RSYNC=/usr/bin/rsync
RSYNC_OPTIONS="-rvtlH --progress --delay-updates --delete-after --safe-links --temp-dir=$DESTPATH/.rsynctemp"

LOG_PREFIX="Toasted Mirrors:"

fixpermissions() {
    echo "$LOG_PREFIX Fix file permissions"

    find "$DESTPATH" -type d -exec chmod 775 {} \;
    find "$DESTPATH" -type f -exec chmod 644 {} \;
}

synchronize() {
    echo "$LOG_PREFIX Manjaro sync"
    $RSYNC $RSYNC_OPTIONS \
        rsync://ftp.tsukuba.wide.ad.jp/manjaro/ "$DESTPATH/manjaro"
    sleep 2

    echo "$LOG_PREFIX Ubuntu-ports sync"
    $RSYNC $RSYNC_OPTIONS \
        --exclude "*powerpc.deb" --exclude "*ppc64el.deb" --exclude "*s390x.deb" --exclude "*riscv64.deb" \
        --exclude "*powerpc.udeb" --exclude "*ppc64el.udeb" --exclude "*s390x.udeb" --exclude "*riscv64.udeb" \
        rsync://ports.ubuntu.com/ubuntu-ports/ "$DESTPATH/ubuntu-ports"
    sleep 2

    echo "$LOG_PREFIX Raspbian sync"
    $RSYNC $RSYNC_OPTIONS \
        rsync://muug.ca/mirror/raspbian/raspbian/ "$DESTPATH/raspbian"
    sleep 2

    # Only need to run this every so often
    (( RANDOM % 6 == 0 )) && fixpermissions
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
