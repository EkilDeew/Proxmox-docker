FROM debian:bookworm-slim

RUN apt update && apt -y upgrade && \
    apt --no-install-recommends -y install \
        iproute2 \
        jq \
        tcpdump \
        iputils-ping \
        python3 \
        qemu-system-x86 \
        udhcpd \
        net-tools \
        radvd \
        socat \
        mtr-tiny \
        micro \

#        dnsmasq \

        openssh-client \
    && apt clean

COPY run.sh /run/

#COPY dnsmasq.conf /etc/dnsmasq.conf
#RUN mkdir -p /var/log/dnsmasq

VOLUME /image

ENTRYPOINT ["/run/run.sh"]
