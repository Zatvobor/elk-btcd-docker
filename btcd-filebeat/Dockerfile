FROM phusion/baseimage
MAINTAINER Oleksiy Zatvornitskyy <oleksiy.zatvornitskyy@bitfury.com>

RUN apt-get update -qq \
  && apt-get install -y curl git \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Setup filebeat
ENV FILEBEAT_VERSION 1.3.1_amd64
ENV FILEBEAT_PACKAGE filebeat_$FILEBEAT_VERSION.deb
ENV FILEBEAT_DOWNLOAD_URL https://download.elastic.co/beats/filebeat/$FILEBEAT_PACKAGE
RUN cd /tmp \
 && curl -sSL "$FILEBEAT_DOWNLOAD_URL" -o $FILEBEAT_PACKAGE \
 && dpkg -i $FILEBEAT_PACKAGE \
 && rm $FILEBEAT_PACKAGE

## config file
ADD ./filebeat.yml /etc/filebeat/filebeat.yml

## CA cert
RUN mkdir -p /etc/pki/tls/certs
ADD ./logstash-beats.crt /etc/pki/tls/certs/logstash-beats.crt

## start shell script
ADD ./start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Setup Golang
ENV GOLANG_VERSION 1.7.1
ENV GOLANG_DOWNLOAD_URL https://storage.googleapis.com/golang/go$GOLANG_VERSION.linux-amd64.tar.gz
ENV GOLANG_SHA256 43ad621c9b014cde8db17393dc108378d37bc853aa351a6c74bf6432c1bbd182

ENV PATH /usr/local/go/bin:$PATH
ENV HOME /btcd
ENV GOPATH $HOME

RUN cd /tmp \
  && curl -sSL "$GOLANG_DOWNLOAD_URL" -o go$GOLANG_VERSION.linux-amd64.tar.gz \
  && tar -C /usr/local -xzf go$GOLANG_VERSION.linux-amd64.tar.gz

# Setup btcd from master branch
ENV PATH $HOME/bin:$PATH
ENV BTCD_GIT_URL https://github.com/zatvobor/btcd.git
RUN mkdir /btcd
RUN cd /btcd \
  && go get -u github.com/Masterminds/glide \
  && git clone $BTCD_GIT_URL $GOPATH/src/github.com/btcsuite/btcd \
  && cd $GOPATH/src/github.com/btcsuite/btcd \
  && glide install \
  && go install . ./cmd/...

## configure BTCD
ADD ./btcd.conf /etc/btcd/btcd.conf

## configure shared resources
VOLUME /var/lib/btcd
EXPOSE 8333


CMD '/usr/local/bin/start.sh'
