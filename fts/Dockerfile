# FTS3 server and REST with DEP DLM's davix/gfal2/FTS3 changes.
# fts-rest-flask source patches are not baked in: deployments mount them at
# runtime over /tmp/fts-rest-flask/src (made against v${FTS_VERSION}).
FROM almalinux:9 AS builder

# FTS_VERSION: fts-rest-flask tag (and the image's readable tag)
# DAVIX_COMMIT: upstream, SigV4 header signing (cern-fts/davix#150)
# GFAL2_COMMIT: fork, SIGV4_HEADER_MODE (cern-fts/gfal2#28)
# FTS3_COMMIT: fork, 3.14.x-release (v3.14.0-65) + token/S3 fixes
ARG FTS_VERSION=3.14.4
ARG DAVIX_COMMIT=3198e7fee2ccbd60ba36d8408eb112f8445e99b8
ARG GFAL2_COMMIT=bb4f21123a1353f7fc66d45785c9b6f699d1efd8
ARG FTS3_COMMIT=9d05b26d3d7c68fc0a0f1c781b91b4683562b840
RUN dnf install -y epel-release && \
    /usr/bin/crb enable && \
    dnf install -y \
    cmake gcc gcc-c++ make git python3 python3-pip \
    openssl-devel boost-devel glib2-devel \
    json-c-devel pugixml-devel \
    openldap-devel xrootd-client-devel libssh2-devel \
    libuuid-devel cryptopp-devel jsoncpp-devel \
    protobuf-devel cppzmq-devel doxygen \
    mysql-devel systemd-devel nlohmann-json-devel \
    curl-devel gtest-devel libxml2-devel gsoap-devel \
    libdirq-devel activemq-cpp-devel globus-gsi-credential-devel \
    soci-devel soci-mysql-devel gridsite-devel voms-devel \
    httpd-devel swig python3-devel \
    && dnf clean all

RUN git clone https://github.com/cern-fts/davix.git /tmp/davix && \
    cd /tmp/davix && git checkout ${DAVIX_COMMIT} && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DENABLE_THIRD_PARTY_COPY=ON && \
    make -j$(nproc) && make install && \
    rm -rf /tmp/davix

RUN git clone https://github.com/mgajek-cern/gfal2.git /tmp/gfal2 && \
    cd /tmp/gfal2 && git checkout ${GFAL2_COMMIT} && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr \
    -DPLUGIN_DCAP=OFF -DPLUGIN_GRIDFTP=OFF -DPLUGIN_SFTP=OFF -DPLUGIN_SRM=OFF \
    -DPLUGIN_XROOTD=ON -DPLUGIN_HTTP=ON -DPLUGIN_FILE=ON -DSKIP_TESTS=TRUE && \
    make -j$(nproc) && make install && \
    rm -rf /tmp/gfal2

RUN git clone https://gitlab.cern.ch/nramosga/fts3.git /tmp/fts3 && \
    cd /tmp/fts3 && git checkout ${FTS3_COMMIT} && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DALLBUILD=ON && \
    make -j$(nproc) && make install && \
    rm -rf /tmp/fts3

RUN git clone https://gitlab.cern.ch/fts/fts-rest-flask.git /tmp/fts-rest-flask && \
    cd /tmp/fts-rest-flask && git checkout v${FTS_VERSION} && \
    pip3 install setuptools_scm && \
    pip3 install -r requirements.in && \
    pip3 install cryptography && \
    pip3 install --no-deps -e . && \
    mkdir -p /usr/libexec/fts3rest && \
    cp src/fts3rest/fts3rest.wsgi /usr/libexec/fts3rest/fts3rest.wsgi

FROM almalinux:9 AS runtime

RUN dnf install -y epel-release && \
    /usr/bin/crb enable && \
    dnf install -y \
    python3 python3-pip \
    openssl glib2 openldap \
    xrootd-client libssh2 libuuid cryptopp jsoncpp \
    protobuf zeromq libxml2 gsoap \
    libdirq activemq-cpp globus-gsi-credential \
    soci-mysql gridsite voms voms-clients \
    python3-mysqlclient mysql cronie \
    httpd mod_ssl python3-mod_wsgi \
    boost-thread boost-filesystem boost-system \
    boost-chrono boost-date-time boost-regex \
    boost-iostreams boost-atomic boost-timer \
    boost-program-options pugixml \
    gfal2-util-scripts python3-gfal2 gfal2-plugin-http \
    && dnf clean all

RUN pip3 install "sqlalchemy<2.0" pymysql cryptography

COPY --from=builder /usr/sbin/fts_* /usr/sbin/
COPY --from=builder /usr/lib64/libgfal_transfer* /usr/lib64/
COPY --from=builder /usr/lib64/libfts* /usr/lib64/
COPY --from=builder /usr/lib64/libdavix* /usr/lib64/
COPY --from=builder /usr/lib64/libgfal2* /usr/lib64/
COPY --from=builder /usr/lib64/gfal2-plugins/ /usr/lib64/gfal2-plugins/
COPY --from=builder /usr/bin/gfal-* /usr/bin/
COPY --from=builder /usr/etc/gfal2.d/ /etc/gfal2.d/
COPY --from=builder /usr/share/fts/ /usr/share/fts/
COPY --from=builder /usr/share/fts-mysql/ /usr/share/fts-mysql/
COPY --from=builder /usr/libexec/fts3rest/ /usr/libexec/fts3rest/
COPY --from=builder /tmp/fts-rest-flask /tmp/fts-rest-flask
COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY --from=builder /usr/local/lib64/python3.9/site-packages /usr/local/lib64/python3.9/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

RUN useradd -r -m -u 9003 fts3 && \
    mkdir -p /var/log/fts3 /var/log/fts3rest /etc/fts3 /var/lib/fts3 \
             /etc/grid-security/certificates /etc/gfal2.d /usr/etc && \
    ln -s /etc/gfal2.d /usr/etc/gfal2.d && \
    touch /var/log/fts3/fts3server.log /var/log/fts3rest/fts3rest.log && \
    chown -R fts3:fts3 /var/log/fts3 /var/log/fts3rest /var/lib/fts3 && \
    chmod +x /usr/share/fts/fts-database-upgrade.py

# Disable default httpd configs that conflict
RUN for f in ssl autoindex userdir welcome zgridsite; do : > /etc/httpd/conf.d/$f.conf; done && \
    echo "ServerName fts" >> /etc/httpd/conf/httpd.conf

COPY files/fts3rest.conf /etc/httpd/conf.d/fts3rest.conf
COPY files/fts-activemq.conf /etc/fts3/fts-activemq.conf
COPY --chmod=0755 files/wait-for-it.sh files/logshow /usr/local/bin/
COPY --chmod=0755 files/docker-entrypoint.sh /docker-entrypoint.sh

RUN cp /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem /etc/grid-security/certificates/ca-bundle.pem && \
    openssl rehash /etc/grid-security/certificates

# Certificates come at runtime (volume mounts or Kubernetes secrets):
#   /etc/grid-security/hostcert.pem (0644), hostkey.pem (0600), certificates/
EXPOSE 8446 8449
ENTRYPOINT ["/docker-entrypoint.sh"]
