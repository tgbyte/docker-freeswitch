FROM debian:11

ARG FREESWITCH_VERSION
ARG SIGNALWIRE_ACCESS_TOKEN

COPY Makefile /tmp/

RUN set -x \
   && apt-get update -qq \
   && apt-get upgrade -y -qq \
   && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends -q \
              curl \
   && sed -i "s/httpredir.debian.org/`curl -s -D - http://httpredir.debian.org/demo/debian/ | awk '/^Link:/ { print $2 }' | sed -e 's@<http://\(.*\)/debian/>;@\1@g'`/" /etc/apt/sources.list \
   && DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
              ca-certificates \
              gnupg \
              lsb-release \
              wget \
   && wget --http-user=signalwire --http-password=$SIGNALWIRE_ACCESS_TOKEN \
      -O /usr/share/keyrings/signalwire-freeswitch-repo.gpg \
      https://freeswitch.signalwire.com/repo/deb/debian-release/signalwire-freeswitch-repo.gpg \
   && echo "machine freeswitch.signalwire.com login signalwire password $SIGNALWIRE_ACCESS_TOKEN" > /etc/apt/auth.conf \
   && echo "deb [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ `lsb_release -sc` main" > /etc/apt/sources.list.d/freeswitch.list \
   && echo "deb-src [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ `lsb_release -sc` main" >> /etc/apt/sources.list.d/freeswitch.list \
   && apt-get update -qq \
   && DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
              freeswitch-meta-all \
              build-essential \
              devscripts \
              git \
              libfreeswitch-dev \
              libmosquitto1 \
              libmosquitto-dev \
              lua-cjson \
              lua-http \
              lua-json \
              lua5.3 \
              opus-tools \
              vorbis-tools \
              xmlstarlet \
   && full_freeswitch_version=$(apt-cache show freeswitch --no-all-versions | grep Version | egrep -o '[0-9]+\.[0-9.]+\.[0-9.]+') \
   && if [ "${full_freeswitch_version}" != "${FREESWITCH_VERSION}" ]; then echo "Inconsistent FreeSWITCH version. Expected: ${FREESWITCH_VERSION}. Got: ${full_freeswitch_version}. Aborting build..."; exit 1; fi \
   && mkdir /build \
   && cd /build \
   && DEBIAN_FRONTEND=noninteractive \
        mk-build-deps -i -t "apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y" freeswitch \
   && dpkg -i freeswitch-build-deps*.deb \
   && git clone https://github.com/freeswitch/mod_mosquitto.git \
   && cd /build/mod_mosquitto \
   && mv /tmp/Makefile . \
   && make install \
   && cd / \
   && rm -rf /build \
   && apt-get remove --purge -y \
        build-essential \
        devscripts \
        freeswitch-build-deps \
        freeswitch-sounds-ru-ru-vika \
        freeswitch-sounds-pt-br-karina \
        freeswitch-sounds-fr-ca-june \
        freeswitch-sounds-es-ar-mario \
        git \
        libmosquitto-dev \
        wget \
   && apt-get clean autoclean \
   && apt-get autoremove --yes --purge

ADD freeswitch-sounds-de-tts-google-16000-1.0.4.tar.gz /usr/share/freeswitch/sounds/
ADD freeswitch-sounds-de-tts-google-8000-1.0.4.tar.gz /usr/share/freeswitch/sounds/

# Used for SIP signaling (Standard SIP Port, for default Internal Profile)
EXPOSE 5060/tcp 5060/udp

# Used for SIP signaling (For default "External" Profile)
EXPOSE 5080/tcp 5080/udp

# Used for WebRTC (Websocket)
EXPOSE 5066/tcp 7443/tcp

# Used for Verto
EXPOSE 8081/tcp 8082/tcp

# Used for mod_event_socket * (ESL)
EXPOSE 8021/tcp

# Used for audio/video data in SIP and other protocols (RTP/ RTCP multimedia streaming)
EXPOSE 64535-65535/udp

ENV FREESWITCH_ESL_PASSWORD=

# Healthcheck to make sure the service is running
SHELL       ["/bin/bash"]
HEALTHCHECK --interval=15s --timeout=5s \
    CMD  fs_cli --password=${FREESWITCH_ESL_PASSWORD} -x status | grep -q ^UP || exit 1

CMD ["/usr/bin/freeswitch", "-nf", "-nc", "-rp"]
