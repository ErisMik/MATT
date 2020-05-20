#!/bin/bash

DESTPATH=/usr/share/nginx/html/mirrors
LOCKFILE=/tmp/rsync-mirrors.lock

RSYNC=/usr/bin/rsync
RSYNC_OPTIONS="-rvtlH --progress --delay-updates --delete-after --safe-links --temp-dir=$DESTPATH/.rsynctemp"

DEBIAN_IGNORE=" \
    --exclude '*powerpc.deb' --exclude '*powerpc.udeb' \
    --exclude '*ppc64el.deb' --exclude '*ppc64el.udeb' \
    --exclude '*s390x.deb' --exclude '*s390x.udeb' \
    --exclude '*riscv64.deb' --exclude '*riscv64.udeb' \
    --exclude '*i386.deb' --exclude '*i386.udeb' \
    --exclude '*mips.deb' --exclude '*mips.udeb' \
    --exclude '*mips64el.deb' --exclude '*mips64el.udeb' \
    --exclude '*mipsel.deb' --exclude '*mipsel.udeb' \
    --exclude '*mipsel.deb' --exclude '*mipsel.udeb' \
"

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
        $DEBIAN_IGNORE
        rsync://ports.ubuntu.com/ubuntu-ports/ "$DESTPATH/ubuntu-ports"
    sleep 2

    echo "$LOG_PREFIX Raspbian sync"
    $RSYNC $RSYNC_OPTIONS \
        rsync://muug.ca/mirror/raspbian/raspbian/ "$DESTPATH/raspbian"
    sleep 2

    echo "$LOG_PREFIX Arch Linux Sync"
    $RSYNC $RSYNC_OPTIONS \
        rsync://mirror.csclub.uwaterloo.ca/archlinux/ "$DESTPATH/archlinux"
    sleep 2

    echo "$LOG_PREFIX Debian Sync"
    $RSYNC $RSYNC_OPTIONS \
        $DEBIAN_IGNORE
        rsync://ftp.ca.debian.org/debian/ "$DESTPATH/debian"
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
