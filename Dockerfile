# rootfs builder
FROM alpine:3.15.6 as rootfs-builder

COPY rootfs/ /rootfs/
COPY patches/ /tmp/
ADD https://github.com/ElizarovEugene/TorrentMonitor/archive/refs/heads/master.zip /tmp/tm-latest.zip

RUN apk --no-cache add \
        unzip \
        sqlite \
        patch \
        && \
    unzip /tmp/tm-latest.zip -d /tmp/ && \
    mv /tmp/TorrentMonitor-master/* /rootfs/data/htdocs && \
    cat /rootfs/data/htdocs/db_schema/sqlite.sql | sqlite3 /rootfs/data/htdocs/db_schema/tm.sqlite

# Main image
FROM alpine:3.15.6
MAINTAINER Alexander Fomichev <fomichev.ru@gmail.com>
LABEL org.opencontainers.image.source="https://github.com/alfonder/torrentmonitor-dockerized/"

ENV VERSION="2.1.8" \
    RELEASE_DATE="23.05.2025" \
    CRON_TIMEOUT="0 * * * *" \
    CRON_COMMAND="php -q /data/htdocs/engine.php 2>&1" \
    PHP_TIMEZONE="UTC" \
    PHP_MEMORY_LIMIT="512M" \
    LD_PRELOAD="/usr/lib/preloadable_libiconv.so"

COPY --from=rootfs-builder /rootfs/ /

RUN apk --no-cache add \
        nginx \
        shadow \
        php7 \
        php7-common \
        php7-fpm \
        php7-curl \
        php7-sqlite3 \
        php7-pdo_sqlite \
        php7-xml \
        php7-json \
        php7-simplexml \
        php7-session \
        php7-iconv \
        php7-mbstring \
        php7-ctype \
        php7-zip \
        php7-dom \
        && \
    apk add gnu-libiconv=1.15-r3 --update-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.13/community/

LABEL ru.korphome.version="${VERSION}" \
      ru.korphome.release-date="${RELEASE_DATE}"

VOLUME ["/data/htdocs/db", "/data/htdocs/torrents"]
WORKDIR /
EXPOSE 80

ENTRYPOINT ["/init"]
