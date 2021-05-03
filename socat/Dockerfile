ARG BASE_IMAGE=quay.io/airshipit/alpine:latest
FROM ${BASE_IMAGE} as alpine

RUN apk update && apk --no-cache add socat

ENTRYPOINT ["socat"]
