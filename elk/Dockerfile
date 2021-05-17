FROM docker:stable

RUN apk add --update bash

COPY entrypoint.sh /entrypoint.sh
COPY config /config

ENTRYPOINT ["/entrypoint.sh"]
