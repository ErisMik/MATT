#!/bin/bash

TARGET_DIR="$1"
if [ -z "$TARGET_DIR" ]; then
    echo "TARGET_DIR is blank"
    exit 1
fi
echo "Directory is set to '$TARGET_DIR'"

cd "$TARGET_DIR"
wget https://aur.archlinux.org/packages.gz -O packages.gz.new
mv packages.gz.new packages.gz
gzip -dkf packages.gz

syncRepo() {
    if [ -d "$2/$1.git" ]; then
        echo "Updating $1"
        cd "$2/$1.git"
        git remote update
    else
        echo "Fetching $1"
        cd "$2"
        git clone --mirror "https://aur.archlinux.org/$1.git"
        cd "$2/$1.git"
        git update-server-info
    fi
    return 0
}
export -f syncRepo

grep -v '^#' <packages | sort | parallel syncRepo {} "$TARGET_DIR"
