FROM phusion/baseimage
MAINTAINER Oleksiy Zatvornitskyy <oleksiy.zatvornitskyy@bitfury.com>

RUN apt-get update -qq \
  && apt-get install -y curl git \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV HOME /btcd
RUN /usr/sbin/useradd -s /bin/bash -m -d /btcd btcd

RUN chown btcd:btcd -R /btcd

ENV GOLANG_VERSION 1.7.1
ENV GOLANG_DOWNLOAD_URL https://storage.googleapis.com/golang/go$GOLANG_VERSION.linux-amd64.tar.gz
ENV GOLANG_SHA256 43ad621c9b014cde8db17393dc108378d37bc853aa351a6c74bf6432c1bbd182

ENV PATH /usr/local/go/bin:$PATH
ENV GOPATH $HOME

RUN cd /tmp \
  && curl -sSL "$GOLANG_DOWNLOAD_URL" -o go$GOLANG_VERSION.linux-amd64.tar.gz \
  && tar -C /usr/local -xzf go$GOLANG_VERSION.linux-amd64.tar.gz

USER btcd
ENV PATH $HOME/bin:$PATH
RUN cd /btcd \
  && go get -u github.com/Masterminds/glide \
  && git clone https://github.com/zatvobor/btcd.git $GOPATH/src/github.com/btcsuite/btcd \
  && cd $GOPATH/src/github.com/btcsuite/btcd \
  && glide install \
  && go install . ./cmd/...

### configure BTCD
ADD ./btcd.conf /etc/btcd/btcd.conf

VOLUME /var/lib/btcd
EXPOSE 8333

USER btcd
WORKDIR /btcd
CMD /bin/sh -c "btcd --configfile=/etc/btcd/btcd.conf"
