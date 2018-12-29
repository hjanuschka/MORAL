FROM debian:latest
MAINTAINER Helmut Januschka <helmut@januschka.com>

RUN apt-get update && apt-get install -y ipvsadm \
                                         build-essential \
                                         openssl \
                                         curl \
                                         zlib1g \
                                         zlib1g-dev \
                                         libssl-dev \
                                         libyaml-dev \
                                         libsqlite3-dev \
                                         sqlite3 \
                                         libxml2-dev \
                                         libxslt-dev \
                                         autoconf \
                                         libc6-dev \
                                         ncurses-dev \
                                         automake \
                                         libtool \
                                         bison \
                                         pkg-config



# install RVM, Ruby, and Bundler
RUN \curl -L https://get.rvm.io | bash -s stable
RUN /bin/bash -l -c "rvm requirements"
RUN /bin/bash -l -c "rvm install 2.5"
RUN /bin/bash -l -c "gem install bundler --no-ri --no-rdoc"


