FROM phusion/baseimage

RUN apt-get update -qq \
  && apt-get install -y curl git \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

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

CMD btcd --configfile=/etc/btcd/btcd.conf
