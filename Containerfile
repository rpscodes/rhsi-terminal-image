# kcat builder
FROM registry.redhat.io/devspaces/udi-rhel8:3.8 AS kafkacat
USER root
RUN dnf -y install gcc which gcc-c++ wget make git cmake
ENV KCAT_VERSION=1.7.0
RUN dnf -y install cyrus-sasl-devel libcurl-devel
RUN cd /tmp && git clone https://github.com/edenhill/kcat -b $KCAT_VERSION --single-branch && \
    cd kcat && \
    ./bootstrap.sh

# main image
FROM registry.redhat.io/devspaces/udi-rhel8:3.8

ENV CAMELK_VERSION=1.10.0
ENV JBANG_VERSION=0.108.0
ENV SKUPPER_VERSION=1.4.4-1
ENV TKN_VERSION=1.11.0
ENV KN_VERSION=1.8.1

USER root

ADD RPMS /tmp/install

# Install skupper
RUN dnf install -y /tmp/install/skupper-cli-${SKUPPER_VERSION}.el8.x86_64.rpm && \
    dnf clean all



# Install httpie
RUN wget https://packages.httpie.io/binaries/linux/http-latest -O /usr/local/bin/http && \
    ln -s /usr/local/bin/http /usr/local/bin/https && \ 
    chmod +x /usr/local/bin/http



# Licenses
RUN mkdir /licenses
COPY LICENSE* /licenses/

RUN for f in "/home/user" "/projects"; do \
      chgrp -R 0 ${f} && \
      chmod -R g=u ${f}; \
    done

WORKDIR /projects
CMD tail -f /dev/null
