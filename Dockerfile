# docker-joinmarket
# Copyright (C) 2019  Simon Castano
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# Contact author per email: <mailto:simon@brane.cc>

FROM python:3.9-slim

ARG UID=1040
ARG GUID=65539
ARG VERSION
ARG PGP_KEY=2B6FC204D9BF332D062B461A141001A1AF77F20B
ARG DEBIAN_FRONTEND=noninteractive

# make Apt non-interactive
RUN echo 'APT::Get::Assume-Yes "true";' > /etc/apt/apt.conf.d/90joinmarket \
  && echo 'DPkg::Options "--force-confnew";' >> /etc/apt/apt.conf.d/90joinmarket

ENV IMAGE_UID ${UID}
ENV IMAGE_GUID ${GUID}
ENV VERSION ${VERSION}
ENV PGP_KEY ${PGP_KEY}

ENV USER_NAME jm

# Install OS utilities
RUN set -ex \
  # Setup environment
  && groupadd -g $IMAGE_GUID docker \
  && useradd -g docker -m -d /$USER_NAME -u $IMAGE_UID $USER_NAME \
  # Install depedencies
  && apt-get -qq update \
  && apt-get -qq install --no-install-recommends --no-install-suggests \
  ca-certificates \
  wget \
  gpg \
  dirmngr \
  gpg-agent \
  pkg-config \
  libtool \
  libffi-dev \
  libgmp-dev \
  libsodium-dev \
  gosu \
  nano \
  procps \
  build-essential \
  automake \
  unzip &&\
  # Build and install libsecp256k1
  wget -qO /tmp/libsecp256k1.zip https://github.com/bitcoin-core/secp256k1/archive/master.zip &&\
  unzip /tmp/libsecp256k1.zip -d /tmp &&\
  cd /tmp/secp256k1-master &&\
  ./autogen.sh &&\
  ./configure \
      --enable-module-recovery \
      --enable-experimental \
      --enable-module-ecdh \
      --enable-benchmark=no \
      MAKE=make &&\
  make &&\
  if ! make check; then \
      exit 1; \
  fi &&\
  make install &&\
  # Download JoinMarket archive
  TAR_URL="https://github.com/JoinMarket-Org/joinmarket-clientserver/archive/v${VERSION}.tar.gz" \
  && ASC_URL="https://github.com/JoinMarket-Org/joinmarket-clientserver/releases/download/v${VERSION}/joinmarket-clientserver-${VERSION}.tar.gz.asc" \
  && wget -qO /tmp/jm.tar.gz $TAR_URL \
  && wget -qO /tmp/jm.asc $ASC_URL \
  # Verify JoinMarket archive signature
  && found=''; \
  for server in \
  hkp://keyserver.ubuntu.com:80 \
  ha.pool.sks-keyservers.net \
  hkp://p80.pool.sks-keyservers.net:80 \
  ipv4.pool.sks-keyservers.net \
  keys.gnupg.net \
  pgp.mit.edu \
  ; do \
  echo "Fetching GPG key ${PGP_KEY} from $server"; \
  gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys "${PGP_KEY}" && found=yes && break; \
  done; \
  test -z "$found" && echo >&2 "error: failed to fetch PGP key ${PGP_KEY}" && exit 1; \
  gpg --verify /tmp/jm.asc /tmp/jm.tar.gz \
  # Install JoinMarket
  && tar -xzvf /tmp/jm.tar.gz -C /$USER_NAME --strip-components=1 \
  && cd /$USER_NAME \
  && pip install -r requirements/base.txt \
  && pip install scipy matplotlib \
  && python setupall.py --daemon \
  && python setupall.py --client-bitcoin \
  # Clean
  && apt-get -qq remove --purge --autoremove \
  ca-certificates \
  wget \
  gpg \
  dirmngr \
  gpg-agent \
  pkg-config \
  libtool \
  libffi-dev \
  libgmp-dev \
  build-essential \
  automake \
  unzip \
  && apt-get -qq clean \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /tmp/*

COPY entrypoint.sh /usr/bin

WORKDIR /$USER_NAME/scripts

ENTRYPOINT ["entrypoint.sh"]
CMD ["python", "joinmarketd.py"]
