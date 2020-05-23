#!/bin/bash

DESTPATH=/usr/share/nginx/html/mirrors
LOCKFILE=/tmp/rsync-mirrors.lock

DEBIAN_EXCLUDEFILE=/etc/matt/debian_exclude.txt

RSYNC=/usr/bin/rsync
RSYNC_OPTIONS="-rvtlH --progress --delay-updates --delete-after --safe-links --temp-dir=$DESTPATH/.rsynctemp"

LOG_PREFIX="Toasted Mirrors:"

fixpermissions() {
    echo "$LOG_PREFIX Fix file permissions"

    find "$DESTPATH" -path "$DESTPATH/aur" -prune -o -type d -exec chmod 775 {} \;
    find "$DESTPATH" -path "$DESTPATH/aur" -prune -o -type f -exec chmod 644 {} \;
}

synchronize() {
    echo "$LOG_PREFIX Manjaro sync"
    cmd="$RSYNC $RSYNC_OPTIONS rsync://ftp.tsukuba.wide.ad.jp/manjaro/ $DESTPATH/manjaro"
    echo "$cmd" && sleep 2
    $cmd

    echo "$LOG_PREFIX Ubuntu-ports sync"
    cmd="$RSYNC $RSYNC_OPTIONS --exclude-from=$DEBIAN_EXCLUDEFILE rsync://ports.ubuntu.com/ubuntu-ports/ $DESTPATH/ubuntu-ports"
    echo "$cmd" && sleep 2
    $cmd

    echo "$LOG_PREFIX Raspbian sync"
    cmd="$RSYNC $RSYNC_OPTIONS rsync://muug.ca/mirror/raspbian/raspbian/ $DESTPATH/raspbian"
    echo "$cmd" && sleep 2
    $cmd

    echo "$LOG_PREFIX Arch Linux Sync"
    cmd="$RSYNC $RSYNC_OPTIONS rsync://mirror.csclub.uwaterloo.ca/archlinux/ $DESTPATH/archlinux"
    echo "$cmd" && sleep 2
    $cmd

    echo "$LOG_PREFIX Debian Sync"
    cmd="$RSYNC $RSYNC_OPTIONS --exclude-from=$DEBIAN_EXCLUDEFILE rsync://ftp.ca.debian.org/debian/ $DESTPATH/debian"
    echo "$cmd" && sleep 2
    $cmd

    echo "$LOG_PREFIX AUR Sync"
    cmd="/etc/matt/aursync.sh $DESTPATH/aur"
    echo "$cmd" && sleep 2
    $cmd

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
