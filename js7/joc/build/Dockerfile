# BUILD PRE-IMAGE

FROM alpine:3.20 AS js7-pre-image

# provide build arguments for release information
ARG JS_RELEASE
ARG JS_RELEASE_MAJOR

# image user id has to match later run-time user id
ARG JS_USER_ID=${JS_USER_ID:-1001}
ARG JS_HTTP_PORT=${JS_HTTP_PORT:-4446}
ARG JS_HTTPS_PORT=${JS_HTTPS_PORT:-4443}
ARG JS_JAVA_OPTIONS=${JS_JAVA_OPTIONS}

# add/copy installation tarball
ADD https://download.sos-berlin.com/JobScheduler.${JS_RELEASE_MAJOR}/js7_joc_linux.${JS_RELEASE}.tar.gz /usr/local/src/
#COPY js7_joc_linux.${JS_RELEASE}.tar.gz /usr/local/src/

# test installer tarball
RUN test -e /usr/local/src/js7_joc_linux.${JS_RELEASE}.tar.gz

# add/copy installer script
ADD  https://download.sos-berlin.com/JobScheduler.${JS_RELEASE_MAJOR}/js7_install_joc.sh /usr/local/bin/
#COPY js7_install_joc.sh /usr/local/bin/

# copy configuration
COPY config/ /usr/local/src/resources

# install Java and JOC Cockpit
#   create user account jobscheduler using root group
RUN apk upgrade --available && apk add --no-cache \
    openjdk17-jre && \
    sed -i 's/securerandom.source=file:\/dev\/random/securerandom.source=file:\/dev\/urandom/g' /usr/lib/jvm/java-17-openjdk/conf/security/java.security && \
    adduser -u ${JS_USER_ID} -G root --disabled-password --home /home/jobscheduler --shell /bin/bash jobscheduler && \
    chmod +x /usr/local/bin/js7_install_joc.sh && \
    printf "http port %s https port %s \n", "${JS_HTTP_PORT}", "${JS_HTTPS_PORT}" && \
    /usr/local/bin/js7_install_joc.sh \
        --home=/opt/sos-berlin.com/js7/joc \
        --data=/var/sos-berlin.com/js7/joc \
        --setup-dir=/usr/local/src/joc.setup \
        --tarball=/usr/local/src/js7_joc_linux.${JS_RELEASE}.tar.gz \
        --http-port=${JS_HTTP_PORT} \
        --https-port=${JS_HTTPS_PORT} \
        --dbms-init=off \
        --dbms-config=/usr/local/src/resources/hibernate.cfg.xml \
        --keystore=/usr/local/src/resources/https-keystore.p12 \
        --keystore-password=jobscheduler \
        --truststore=/usr/local/src/resources/https-truststore.p12 \
        --truststore-password=jobscheduler \
        --user=jobscheduler \
        --title="JOC Cockpit" \
        --as-user \
        --java-options="${JS_JAVA_OPTIONS}" \
        --make-dirs && \
    rm -f /usr/local/src/js7_joc_linux.${JS_RELEASE}.tar.gz

# BUILD IMAGE

FROM alpine:3.20 AS js7-image

LABEL maintainer="Software- und Organisations-Service GmbH"

# provide build arguments for release information
ARG JS_RELEASE
ARG JS_RELEASE_MAJOR

# image user id has to match later run-time user id
ARG JS_USER_ID=${JS_USER_ID:-1001}
ARG JS_HTTP_PORT=${JS_HTTP_PORT:-4446}
ARG JS_HTTPS_PORT=${JS_HTTPS_PORT:-4443}
ARG JS_JAVA_OPTIONS=${JS_JAVA_OPTIONS}

# JS7 user id, ports and Java options
ENV RUN_JS_USER_ID=${RUN_JS_USER_ID:-1001}
ENV RUN_JS_HTTP_PORT=${RUN_JS_HTTP_PORT:-$JS_HTTP_PORT}
ENV RUN_JS_HTTPS_PORT=${RUN_JS_HTTPS_PORT:-$JS_HTTPS_PORT}
ENV RUN_JS_JAVA_OPTIONS=${RUN_JS_JAVA_OPTIONS:-$JS_JAVA_OPTIONS}

COPY --from=js7-pre-image ["/opt/sos-berlin.com/js7", "/opt/sos-berlin.com/js7"]
COPY --from=js7-pre-image ["/var/sos-berlin.com/js7", "/var/sos-berlin.com/js7"]

# copy entrypoint script
COPY entrypoint.sh /usr/local/bin/

# install process tools, net tools, bash, openjdk
# add jobscheduler user account and group
# for JDK < 12, /dev/random does not provide sufficient entropy, see https://kb.sos-berlin.com/x/lIM3
RUN apk upgrade --available && apk add \
    --no-cache \
    --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main \
    procps \
    net-tools \
    bash \
    su-exec \
    shadow \
    git \
    openjdk17-jre && \
    sed -i 's/securerandom.source=file:\/dev\/random/securerandom.source=file:\/dev\/urandom/g' /usr/lib/jvm/java-17-openjdk/conf/security/java.security && \
    sed -i 's/jdk.tls.disabledAlgorithms=SSLv3, RC4, DES, MD5withRSA, DH keySize < 1024, \\/jdk.tls.disabledAlgorithms=SSLv3, RC4, DES, MD5withRSA, DH keySize < 1024, TLSv1, TLSv1.1, \\/g' /usr/lib/jvm/java-17-openjdk/conf/security/java.security && \
    adduser -u ${JS_USER_ID} -G root --disabled-password --home /home/jobscheduler --shell /bin/bash jobscheduler && \
    mkdir -p /var/log/sos-berlin.com/js7/joc && \
    chown -R jobscheduler:root /opt/sos-berlin.com /var/sos-berlin.com /var/log/sos-berlin.com/js7/joc && \
    chmod -R g=u /etc/passwd /opt/sos-berlin.com /var/sos-berlin.com /var/log/sos-berlin.com/js7/joc && \
    chmod +x /usr/local/bin/entrypoint.sh

# START

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

