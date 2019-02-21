# ruby
#
# VERSION               0.0.1

FROM      ruby:2.6-alpine

# Timezone変更
RUN apk add --update \
  bash \
  tzdata \
  && cp /usr/share/zoneinfo/Japan /etc/localtime \
  && apk del tzdata \
  && rm -rf /var/cache/apk/*

