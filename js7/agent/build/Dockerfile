# BUILD PRE-IMAGE

FROM alpine:3.17 AS js7-pre-image

# provide build arguments for release information
ARG JS_RELEASE
ARG JS_RELEASE_MAJOR

# image user id has to match later run-time user id
ARG JS_USER_ID=${UID:-1001}
ARG JS_HTTP_PORT=${JS_HTTP_PORT:-4445}
ARG JS_HTTPS_PORT=${JS_HTTPS_PORT:-""}
ARG JS_JAVA_OPTIONS=${JS_JAVA_OPTIONS}

# add/copy installation tarball
ADD https://download.sos-berlin.com/JobScheduler.${JS_RELEASE_MAJOR}/js7_agent_unix.${JS_RELEASE}.tar.gz /usr/local/src/
#COPY js7_agent_unix.${JS_RELEASE}.tar.gz /usr/local/src/

# test installation tarball
RUN test -e /usr/local/src/js7_agent_unix.${JS_RELEASE}.tar.gz

# add/copy installer script
ADD  https://download.sos-berlin.com/JobScheduler.${JS_RELEASE_MAJOR}/js7_install_agent.sh /usr/local/bin/
#COPY js7_install_agent.sh /usr/local/bin/

RUN adduser -u ${JS_USER_ID} -G root --disabled-password --home /home/jobscheduler --shell /bin/bash jobscheduler && \
    chmod +x /usr/local/bin/js7_install_agent.sh && \
    /usr/local/bin/js7_install_agent.sh \
        --home=/opt/sos-berlin.com/js7/agent \
        --data=/var/sos-berlin.com/js7/agent \
        --tarball=/usr/local/src/js7_agent_unix.${JS_RELEASE}.tar.gz \
        --user=jobscheduler \
        --http-port=${JS_HTTP_PORT} \
        --java-options="${JS_JAVA_OPTIONS}" \
        --make-dirs && \
    rm -f /usr/local/src/js7_agent_unix.${JS_RELEASE}.tar.gz

# BUILD IMAGE

FROM alpine:3.17 AS js7-image

LABEL maintainer="Software- und Organisations-Service GmbH"

# provide build arguments for release information
ARG JS_RELEASE
ARG JS_RELEASE_MAJOR

# default user id has to match later run-time user
ARG JS_USER_ID=${UID:-1001}
ARG JS_HTTP_PORT=${JS_HTTP_PORT:-4445}
ARG JS_HTTPS_PORT=${JS_HTTPS_PORT:-""}
ARG JS_JAVA_OPTIONS=${JS_JAVA_OPTIONS}

# JS7 JobScheduler user id, ports and Java options
ENV RUN_JS_USER_ID=${RUN_JS_USER_ID:-1001}
ENV RUN_JS_HTTP_PORT=${RUN_JS_HTTP_PORT:-$JS_HTTP_PORT}
ENV RUN_JS_HTTPS_PORT=${RUN_JS_HTTPS_PORT}
ENV RUN_JS_JAVA_OPTIONS=${RUN_JS_JAVA_OPTIONS:-$JS_JAVA_OPTIONS}

COPY --from=js7-pre-image ["/opt/sos-berlin.com/js7", "/opt/sos-berlin.com/js7"]
COPY --from=js7-pre-image ["/var/sos-berlin.com/js7", "/var/sos-berlin.com/js7"]

# copy configuration
COPY config/ /var/sos-berlin.com/js7/agent/config/

# copy entrypoint script
COPY entrypoint.sh /usr/local/bin/

# install process tools, net tools, bash, openjdk
# for JDK < 12, /dev/random does not provide sufficient entropy, see https://kb.sos-berlin.com/x/lIM3
# make default user the owner of directories
RUN apk update && apk add --no-cache \
    --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community \
    procps \
    net-tools \
    su-exec \
    bash \
    shadow \
    openjdk11 && \
    sed -i 's/securerandom.source=file:\/dev\/random/securerandom.source=file:\/dev\/urandom/g' /usr/lib/jvm/java-11-openjdk/conf/security/java.security && \
    sed -i 's/jdk.tls.disabledAlgorithms=SSLv3, RC4, DES, MD5withRSA, DH keySize < 1024, \\/jdk.tls.disabledAlgorithms=SSLv3, RC4, DES, MD5withRSA, DH keySize < 1024, TLSv1, TLSv1.1, \\/g' /usr/lib/jvm/java-11-openjdk/conf/security/java.security && \
    adduser -u ${JS_USER_ID} -G root --disabled-password --home /home/jobscheduler --shell /bin/bash jobscheduler && \
    chown -R jobscheduler:root /opt/sos-berlin.com  /var/sos-berlin.com && \
    chmod -R g=u /etc/passwd /opt/sos-berlin.com /var/sos-berlin.com && \
    chmod +x /usr/local/bin/entrypoint.sh

# START

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
