# Mirror All The Things

FROM nginx:latest
LABEL maintainer "Eric Mikulin"

RUN apt-get update -y && apt-get install -y rsync cron rsyslog

RUN rm -rf /usr/share/nginx/html/index.html

COPY nginx.conf /etc/nginx/
COPY toasted_mirrors_sync.sh /etc/cron.hourly/
COPY entrypoint.sh /

VOLUME /usr/share/nginx/html/mirrors
ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
