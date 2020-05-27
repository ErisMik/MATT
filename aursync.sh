#!/bin/bash

TARGET_DIR="$1"
if [ -z "$TARGET_DIR" ]; then
    echo "TARGET_DIR is blank"
    exit 1
fi
echo "Directory is set to '$TARGET_DIR'"

if [ -z "$AURSYNC_FULL" ]; then
    echo "Will perform a delta sync"
else
    echo "Will perform a full sync"
fi

cd "$TARGET_DIR" || exit
wget https://aur.archlinux.org/packages.gz -O packages.gz.new
mv packages.gz.new packages.gz
gzip -dkf packages.gz

syncRepo() {
    if [ -d "$2/$1.git" ]; then
        echo "Updating $1"
        cd "$2/$1.git" || exit
        git -P remote -v update 2>&1
    else
        echo "Fetching $1"
        cd "$2" || exit
        git -P clone --mirror "https://aur.archlinux.org/$1.git" 2>&1
        cd "$2/$1.git" || exit
        git -P update-server-info
    fi
    return 0
}
export -f syncRepo

syncRepoWithCheck() {
    if syncRepo "$1" "$2" | tee /dev/tty | grep -q "up to date"; then
        echo "Repo is up to date, exiting..."
        exit 147
    fi
}
export -f syncRepoWithCheck

if [ -z "$AURSYNC_FULL" ]; then
    PER_PAGE="250"
    PAGE_O="0"

    UPDATE_LOG="/tmp/aursyncupdates"
    echo "" > $UPDATE_LOG

    echo "Performing a delta sync..."
    while true; do
        echo "Packages synced: $PAGE_O"
        curl -s "https://aur.archlinux.org/packages/?O=$PAGE_O&SeB=nd&SB=l&SO=d&PP=$PER_PAGE&do_Search=Go" | grep "<td>" | grep "/packages/" | grep -v "?" | cut -d'<' -f3 | cut -d'>' -f2 |
        while read -r package; do
            # Sometimes the page updates while we sync, check the previous page to see if it is there first and skip if it is
            if tail -250 $UPDATE_LOG | grep -Fx "$package"; then
                continue
            fi

            syncRepoWithCheck "$package" "$TARGET_DIR"
            echo "$package" >> $UPDATE_LOG
        done
        if [[ $? -eq 147 ]]; then
            break
        fi
        PAGE_O=$((PAGE_O + PER_PAGE))
    done

else
    echo "Performing a full sync..."
    grep -v '^#' <packages | sort | parallel syncRepo {} "$TARGET_DIR"
fi
