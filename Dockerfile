FROM ubuntu:16.04
MAINTAINER Tom Xiong <tomxiongzh@gmail.com>

ADD . /build
RUN chmod 750 /build/system_services.sh
RUN /build/system_services.sh 

CMD ["/sbin/my_init"]
