# Mirror All The Things Dockerfile

FROM nginx:latest
LABEL maintainer "Eric Mikulin"

RUN apt-get update -y && apt-get install -y rsync cron vim git parallel wget curl

RUN rm -rf /usr/share/nginx/html/index.html

COPY nginx.conf /etc/nginx/

RUN mkdir -p /etc/matt
COPY debian_exclude.txt /etc/matt/
COPY aursync.sh /etc/matt/

COPY toasted_mirrors_sync.sh /etc/cron.hourly/toasted_mirrors_sync
COPY entrypoint.sh /

VOLUME /usr/share/nginx/html/mirrors
ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
