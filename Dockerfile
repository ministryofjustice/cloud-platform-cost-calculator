FROM alpine:3.12

RUN apk --no-cache add git curl ruby ruby-json

RUN gem install aws-sdk-costexplorer

WORKDIR /root

RUN mkdir lib
COPY post-namespace-costs.rb .
COPY lib/* lib/
