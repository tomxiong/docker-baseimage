FROM ubuntu:14.04
MAINTAINER Phusion <info@phusion.nl> QuantumObject <angel@quantumobject.com>

ENV HOME /root
RUN mkdir -p /build
ADD . /build

RUN chmod 750 /build/prepare.sh && \
	chmod 750 /build/system_services.sh && \
	chmod 750 /build/utilities.sh && \
	chmod 750 /build/cleanup.sh

RUN /build/prepare.sh && \
	/build/system_services.sh && \
	/build/utilities.sh && \
	/build/cleanup.sh

CMD ["/sbin/my_init"]
