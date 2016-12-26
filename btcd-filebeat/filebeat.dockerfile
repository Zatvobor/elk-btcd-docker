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


CMD '/etc/init.d/filebeat start'
