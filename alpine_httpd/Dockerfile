# basic command
# docker build --tag alpine-httpd .

# Build stage
FROM alpine:3.18 AS build

# Set environment variables for versions
ENV OPENSSSL_VERSION=openssl-3.3.1 \
    APR_VERSION=apr-1.7.5 \
    APR_UTIL_VERSION=apr-util-1.6.3 \
    PCRE_VERSION=pcre2-10.44 \
    HTTPD_VERSION=httpd-2.4.62 \
    JK_VERSION=tomcat-connectors-1.2.49-src \
    NGHTTP2_VERSION=v1.48.0 \
    NGHTTP2_NM=nghttp2-1.48.0 \
    INSTALL_PATH=/http/httpd \
    SRC_PATH=/usr/local/src \
    TEMP_DIR=/tmp/install/httpd \
    OPENSSL_PATH=/usr/local/ssl

# Install dependencies and create necessary directories
RUN apk add --no-cache wget make gcc g++ perl libtool expat-dev pcre2-dev openssl-dev linux-headers \
    && mkdir -p ${TEMP_DIR} ${SRC_PATH}


# Download required files
WORKDIR ${TEMP_DIR}
RUN wget https://www.openssl.org/source/${OPENSSSL_VERSION}.tar.gz && \
    wget https://dlcdn.apache.org/apr/${APR_VERSION}.tar.gz && \
    wget https://dlcdn.apache.org/apr/${APR_UTIL_VERSION}.tar.gz && \
    wget https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.44/${PCRE_VERSION}.tar.gz && \
    wget https://dlcdn.apache.org/httpd/${HTTPD_VERSION}.tar.gz && \
    wget https://downloads.apache.org/tomcat/tomcat-connectors/jk/${JK_VERSION}.tar.gz && \
    wget https://github.com/nghttp2/nghttp2/archive/refs/tags/${NGHTTP2_VERSION}.tar.gz

# Extract the downloaded files
RUN tar xvfz ${OPENSSSL_VERSION}.tar.gz && \
    tar xvfz ${APR_VERSION}.tar.gz && \
    tar xvfz ${APR_UTIL_VERSION}.tar.gz && \
    tar xvfz ${PCRE_VERSION}.tar.gz && \
    tar xvfz ${HTTPD_VERSION}.tar.gz && \
    tar xvfz ${JK_VERSION}.tar.gz && \
    tar xvfz ${NGHTTP2_VERSION}.tar.gz && \
    mv ${OPENSSSL_VERSION} ${APR_VERSION} ${APR_UTIL_VERSION} ${PCRE_VERSION} ${HTTPD_VERSION} ${JK_VERSION} ${NGHTTP2_NM} ${SRC_PATH}/

# Install OpenSSL
#RUN cd ${SRC_PATH}/${OPENSSSL_VERSION} && \
 #   ./config && make && make install && \
  #  echo "/usr/local/lib" >> /etc/ld.so.conf.d/openssl.conf && ldconfig && \
  #  cd .. && rm -rf ${SRC_PATH}/${OPENSSSL_VERSION}

# Install OpenSSL
RUN cd ${SRC_PATH}/${OPENSSSL_VERSION} && \
    ./config && make && make install && \
    export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH && \
    cd .. && rm -rf ${SRC_PATH}/${OPENSSSL_VERSION}


# Install APR
RUN cd ${SRC_PATH}/${APR_VERSION} && \
    ./configure --prefix=${SRC_PATH}/${APR_VERSION} && make && make install

# Install APR Util
RUN cd ${SRC_PATH}/${APR_UTIL_VERSION} && \
    ./configure --prefix=${SRC_PATH}/${APR_UTIL_VERSION} --with-apr=${SRC_PATH}/${APR_VERSION} && make && make install

# Install PCRE
RUN cd ${SRC_PATH}/${PCRE_VERSION} && \
    ./configure --prefix=${SRC_PATH}/${PCRE_VERSION} --with-apr-util=${SRC_PATH}/${APR_UTIL_VERSION} --with-apr=${SRC_PATH}/${APR_VERSION} && make && make install


RUN apk add --no-cache cmake
# Download and install nghttp2
RUN cd ${SRC_PATH}/${NGHTTP2_NM} && \
    #./configure && make && make install && \
    cmake . && make && make install && \
    cd .. && rm -rf ${NGHTTP2_NM}

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
                --with-mpm=event \
                --enable-http2 && \
    make && make install && \
    cd .. && rm -rf ${SRC_PATH}/${HTTPD_VERSION}

# Install dependencies and create necessary directories
RUN apk add --no-cache autoconf expat \
    && mkdir -p ${TEMP_DIR} ${SRC_PATH}

# Install Tomcat JK connector
# 2024.09.28 JB : commented by occuring error "jk_global.h:152:10: fatal error: sys/socketvar.h: No such file or directory"
#RUN cd ${SRC_PATH}/${JK_VERSION}/native && \
#    ./buildconf.sh && \
#    ./configure --with-apxs=${INSTALL_PATH}/${HTTPD_VERSION}/bin/apxs && make && make install  && \
#    cd .. && rm -rf ${SRC_PATH}/${JK_VERSION}

# Runtime stage
FROM alpine:3.18

# Set environment variables for versions
ENV HTTPD_VERSION=httpd-2.4.62 \
    INSTALL_PATH=/http/httpd

# Copy only the necessary files from the build stage
COPY --from=build /usr/local /usr/local
COPY --from=build /http/httpd /http/httpd

# Create the wasadm group and httpd user
RUN addgroup -S wasadm && \
    adduser -S -G wasadm httpd && \
    mkdir -p /http/httpd && \
    chown -R httpd:wasadm /http/httpd

# Install dependencies and create necessary directories
RUN apk add --no-cache expat

# Dockerfile의 마지막 부분에 추가
ENV LD_LIBRARY_PATH=/usr/local/lib:/usr/local/src/apr-util-1.6.3/lib


# Switch to the httpd user
USER httpd

# Set the default command to execute when the container starts
CMD ["sh", "-c", "${INSTALL_PATH}/${HTTPD_VERSION}/bin/httpd -DFOREGROUND"]
