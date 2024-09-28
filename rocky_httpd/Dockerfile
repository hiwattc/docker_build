# Build stage
FROM rockylinux/rockylinux:8.10.20240528 AS build

# Set environment variables for versions
ENV OPENSSSL_VERSION=openssl-3.3.1 \
    APR_VERSION=apr-1.7.5 \
    APR_UTIL_VERSION=apr-util-1.6.3 \
    PCRE_VERSION=pcre2-10.44 \
    HTTPD_VERSION=httpd-2.4.62 \
    JK_VERSION=tomcat-connectors-1.2.49-src \
    INSTALL_PATH=/http/httpd \
    SRC_PATH=/usr/local/src \
    TEMP_DIR=/tmp/install/httpd \
    OPENSSL_PATH=/usr/local/ssl


# Create the necessary directories
RUN mkdir -p ${TEMP_DIR} ${SRC_PATH} && \
    yum install -y wget make expat-devel gcc-c++ perl-Pod-Html libtool perl-IPC-Cmd && \
    yum clean all

# Download required files
WORKDIR ${TEMP_DIR}
RUN wget https://www.openssl.org/source/${OPENSSSL_VERSION}.tar.gz && \
    wget https://dlcdn.apache.org/apr/${APR_VERSION}.tar.gz && \
    wget https://dlcdn.apache.org/apr/${APR_UTIL_VERSION}.tar.gz && \
    wget https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.44/${PCRE_VERSION}.tar.gz && \
    wget https://dlcdn.apache.org/httpd/${HTTPD_VERSION}.tar.gz && \
    wget https://downloads.apache.org/tomcat/tomcat-connectors/jk/${JK_VERSION}.tar.gz

# Extract the downloaded files
RUN tar xvfz ${OPENSSSL_VERSION}.tar.gz && \
    tar xvfz ${APR_VERSION}.tar.gz && \
    tar xvfz ${APR_UTIL_VERSION}.tar.gz && \
    tar xvfz ${PCRE_VERSION}.tar.gz && \
    tar xvfz ${HTTPD_VERSION}.tar.gz && \
    tar xvfz ${JK_VERSION}.tar.gz && \
    mv ${OPENSSSL_VERSION} ${APR_VERSION} ${APR_UTIL_VERSION} ${PCRE_VERSION} ${HTTPD_VERSION} ${JK_VERSION} ${SRC_PATH}/

# Install OpenSSL
RUN cd ${SRC_PATH}/${OPENSSSL_VERSION} && \
    ./config && make && make install && \
    echo "/usr/local/lib64" >> /etc/ld.so.conf.d/openssl.conf && ldconfig && \
    cd .. && rm -rf ${SRC_PATH}/${OPENSSSL_VERSION}

# Install APR
RUN cd ${SRC_PATH}/${APR_VERSION} && \
    ./configure --prefix=${SRC_PATH}/${APR_VERSION} && make && make install
# cd .. && rm -rf ${SRC_PATH}/${APR_VERSION}

# Install APR Util
RUN cd ${SRC_PATH}/${APR_UTIL_VERSION} && \
    ./configure --prefix=${SRC_PATH}/${APR_UTIL_VERSION} --with-apr=${SRC_PATH}/${APR_VERSION} && make && make install
    # cd .. && rm -rf ${SRC_PATH}/${APR_UTIL_VERSION}

# Install PCRE
RUN cd ${SRC_PATH}/${PCRE_VERSION} && \
    ./configure --prefix=${SRC_PATH}/${PCRE_VERSION} --with-apr-util=${SRC_PATH}/${APR_UTIL_VERSION} --with-apr=${SRC_PATH}/${APR_VERSION} && make && make install
    # cd .. && rm -rf ${SRC_PATH}/${PCRE_VERSION}

# Install HTTPD
RUN cd ${SRC_PATH}/${HTTPD_VERSION} && \
    export PATH=${SRC_PATH}/${PCRE_VERSION}/bin:$PATH && \
    ./configure --prefix=${INSTALL_PATH}/${HTTPD_VERSION} \
                --enable-modules=most \
                --enable-mods-shared=all \
                --enable-so \
                --with-apr=${SRC_PATH}/${APR_VERSION} \
                --with-apr-util=${SRC_PATH}/${APR_UTIL_VERSION} \
                --with-pcre=${SRC_PATH}/${PCRE_VERSION} \
                --with-ssl=${OPENSSL_PATH} \
                --with-mpm=event && \
    make && make install && \
    cd .. && rm -rf ${SRC_PATH}/${HTTPD_VERSION}

# Install Tomcat JK connector
RUN cd ${SRC_PATH}/${JK_VERSION}/native && \
    ./buildconf.sh && \
    ./configure --with-apxs=${INSTALL_PATH}/${HTTPD_VERSION}/bin/apxs && make && make install  && \
    cd .. && rm -rf ${SRC_PATH}/${JK_VERSION}

# Runtime stage
FROM rockylinux/rockylinux:8.10.20240528

# Set environment variables for versions
ENV HTTPD_VERSION=httpd-2.4.62 \
    INSTALL_PATH=/http/httpd

# Copy only the necessary files from the build stage
COPY --from=build /usr/local /usr/local
COPY --from=build /http/httpd /http/httpd

# Create the wasadm group and httpd user
RUN groupadd wasadm && \
    useradd -g wasadm -s /bin/bash httpd && \
    mkdir -p /http/httpd && \
    chown -R httpd:wasadm /http/httpd

# Configure sudoers for httpd user
RUN yum install -y sudo procps-ng net-tools && \
    echo 'httpd ALL=(ALL) NOPASSWD: /http/httpd/bin/httpd' >> /etc/sudoers.d/httpd && \
    yum clean all

# Switch to the httpd user
USER httpd

# Set the default command to execute when the container starts
#CMD ["/http/httpd/httpd-2.4.62/bin/httpd", "-DFOREGROUND"]
CMD ["sh", "-c", "${INSTALL_PATH}/${HTTPD_VERSION}/bin/httpd -DFOREGROUND"]
