# kcat builder
FROM registry.redhat.io/devspaces/udi-rhel8:3.6 AS kafkacat
USER root
RUN dnf -y install gcc which gcc-c++ wget make git cmake
ENV KCAT_VERSION=1.7.0
RUN dnf -y install cyrus-sasl-devel libcurl-devel
RUN cd /tmp && git clone https://github.com/edenhill/kcat -b $KCAT_VERSION --single-branch && \
    cd kcat && \
    ./bootstrap.sh

# main image
FROM registry.redhat.io/devspaces/udi-rhel8:3.6

ENV CAMELK_VERSION=1.10.0
ENV JBANG_VERSION=0.108.0
ENV SKUPPER_VERSION=1.4.1
ENV TKN_VERSION=1.11.0
ENV KN_VERSION=1.8.1

USER root

# Install skupper
RUN wget https://github.com/skupperproject/skupper/releases/download/${SKUPPER_VERSION}/skupper-cli-${SKUPPER_VERSION}-linux-amd64.tgz \
    -O - | tar -xz -C /usr/local/bin/

# Install kamel
RUN wget https://mirror.openshift.com/pub/openshift-v4/clients/camel-k/${CAMELK_VERSION}/camel-k-client-${CAMELK_VERSION}-linux-64bit.tar.gz \
    -O - | tar -xz -C /usr/local/bin/

# Install JBang
RUN wget https://github.com/jbangdev/jbang/releases/download/v${JBANG_VERSION}/jbang.tar \
    -O - | tar -x --strip 2 -C /usr/local/bin jbang/bin/jbang

# Install Knative
RUN wget https://mirror.openshift.com/pub/openshift-v4/clients/serverless/${KN_VERSION}/kn-linux-amd64.tar.gz \
    -O - | tar -xz -C /usr/local/bin

# Install Tekton
RUN wget https://mirror.openshift.com/pub/openshift-v4/clients/pipeline/${TKN_VERSION}/tkn-linux-amd64.tar.gz \
    -O - | tar -xz -C /usr/local/bin

# Install httpie
RUN wget https://packages.httpie.io/binaries/linux/http-latest -O /usr/local/bin/http && \
    ln -s /usr/local/bin/http /usr/local/bin/https && \ 
    chmod +x /usr/local/bin/http

# Install database clients and utils
RUN curl https://packages.microsoft.com/config/rhel/8/prod.repo > /etc/yum.repos.d/msprod.repo && \ 
    ACCEPT_EULA=Y dnf install -y mssql-tools unixODBC-devel && \
    dnf install -y postgresql-devel python36-devel && \
    dnf clean all && \
    ln -s /opt/mssql-tools/bin/sqlcmd /usr/local/bin/sqlcmd
RUN source /home/user/.venv/bin/activate && \
    pip3 install --upgrade pip && \
    pip3 install setuptools-rust pgcli mycli

# Kafkacat from build
COPY --from=kafkacat /tmp/kcat/kcat /usr/local/bin/kcat
RUN ln -s /usr/bin/kcat /usr/local/bin/kafkacat

# Licenses
RUN mkdir /licenses
COPY LICENSE* /licenses/

RUN for f in "/home/user" "/projects"; do \
      chgrp -R 0 ${f} && \
      chmod -R g=u ${f}; \
    done

WORKDIR /projects
CMD tail -f /dev/null
