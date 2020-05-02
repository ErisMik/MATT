#!/bin/bash

# Fix link-count, as cron doesn't like hardlinks and docker makes hardlink count >0 (very high)
touch /etc/crontab /etc/cron.*/*
service cron start

# Hand off to the CMD
exec "$@"
