FROM debian:buster-slim

LABEL maintainer="roshii <roshii@riseup.net>"

ENV JM_VERSION 0.5.5
ENV JM_URL https://github.com/JoinMarket-Org/joinmarket-clientserver/archive/v$JM_VERSION.tar.gz
ENV JM_ASC_URL https://github.com/JoinMarket-Org/joinmarket-clientserver/releases/download/v$JM_VERSION/joinmarket-clientserver-$JM_VERSION.tar.gz.asc
ENV JM_PGP_KEY 2B6FC204D9BF332D062B461A141001A1AF77F20B
ENV VIRTUAL_ENV=/opt/venv

# Install OS utilities
RUN set -ex \
	&& apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y \
	apt-utils --no-install-recommends \
	&& DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y \
	ca-certificates wget gpg dirmngr gpg-agent gosu \
	--no-install-recommends

# Install JoinMarket dependencies
RUN set -ex \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y \
	python3 python3-dev python3-pip \
	build-essential automake pkg-config libtool \
	libffi-dev libssl-dev libgmp-dev libsodium-dev \
	--no-install-recommends \
	&& rm -rf /var/lib/apt/lists/*

# Install JoinMarket source code
RUN set -ex \
	&& cd /tmp \
	&& wget -qO jm.tar.gz "$JM_URL" \
	&& gpg --keyserver keyserver.ubuntu.com --recv-keys "$JM_PGP_KEY" \
	&& wget -qO jm.asc "$JM_ASC_URL" \
	&& gpg --verify jm.asc jm.tar.gz \
	&& mkdir /jm/clientserver \
	&& tar -xzvf jm.tar.gz -C /jm/clientserver --strip-components=1 \
	&& rm -rf /tmp/*

RUN python3 -m pip install virtualenv --no-cache-dir

RUN python3 -m virtualenv --python=/usr/bin/python3 $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Install dependencies:
RUN set -ex \
	&& pip install -r /jm/clientserver/requirements-dev.txt \
	&& python setupall.py --daemon \
	&& python setupall.py --client-bitcoin

# add user and group with default ids
RUN groupadd joinmarket \
	&& useradd -g joinmarket -s /bin/bash -m -d /jm joinmarket

WORKDIR /jm/clientserver/scripts

COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
CMD ["bash"]
