FROM ruby:2.5
MAINTAINER Helmut Januschka <helmut@januschka.com>

RUN apt-get update && apt-get install -y ipvsadm
ADD docker/run.sh /run.sh
RUN chmod a+rwx /run.sh
CMD /run.sh
