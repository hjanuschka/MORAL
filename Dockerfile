FROM ruby:2.5
MAINTAINER Helmut Januschka <helmut@januschka.com>

RUN apt-get update && apt-get install -y ipvsadm
ADD . /src/
WORKDIR /src/
RUN bundle install
RUN chmod a+rwx /src/docker/run.sh
RUN ls -l /src/docker/
CMD /src/docker/run.sh
