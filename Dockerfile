# Mirror All The Things

FROM nginx:latest
LABEL maintainer "Eric Mikulin"

RUN apt-get update -y && apt-get install -y rsync

COPY nginx.conf /etc/nginx/
COPY toasted_mirrors_sync.sh /etc/cron.hourly/

VOLUME /usr/share/nginx/html/mirrors
