FROM koalaman/shellcheck-alpine:v0.5.0

LABEL maintainer "Marco Ferrari <ferrari.marco@gmail.com>"

RUN apk add --update --no-cache \
  file
