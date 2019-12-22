FROM python:slim-buster AS builder

ARG VERSION=0.6.1
ARG PGP_KEY=2B6FC204D9BF332D062B461A141001A1AF77F20B

ENV VERSION ${VERSION}
ENV PGP_KEY ${PGP_KEY}

ENV SERVICE_USER jm
ENV SERVICE_DATA /jm
ENV VIRTUAL_ENV=/opt/venv

WORKDIR /tmp

# Install OS utilities
RUN set -ex \
	&& apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --no-install-suggests -y \
	ca-certificates \
	wget \
	gpg \
	dirmngr \
	gpg-agent \
	pkg-config \
	libtool \
	libffi-dev \
	# libssl-dev \
	libgmp-dev \
	libsodium-dev \
	&& TAR_URL="https://github.com/JoinMarket-Org/joinmarket-clientserver/archive/v${VERSION}.tar.gz" \
	&& ASC_URL="https://github.com/JoinMarket-Org/joinmarket-clientserver/releases/download/v${VERSION}/joinmarket-clientserver-${VERSION}.tar.gz.asc" \
	&& wget -qO jm.tar.gz $TAR_URL \
	&& wget -qO jm.asc $ASC_URL \
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
	gpg --verify jm.asc jm.tar.gz \
	&& mkdir jm \
	&& tar -xzvf jm.tar.gz -C /tmp/jm --strip-components=1 \
	&& python3 -m pip install virtualenv --no-cache-dir \
	&& python3 -m virtualenv --python=/usr/local/bin/python3 $VIRTUAL_ENV

ENV PATH="$VIRTUAL_ENV/bin:$PATH"

WORKDIR /tmp/jm

# Install dependencies:
RUN set -ex \
	&& pip install -r requirements-dev.txt \
	&& pip install scipy \
	&& python setupall.py --daemon \
	&& python setupall.py --client-bitcoin


FROM python:slim-buster

ENV SERVICE_USER jm
ENV SERVICE_DATA /jm
ENV VIRTUAL_ENV=/opt/venv

RUN set -ex \
	# add user and group with default ids
	&& groupadd -g 65539 docker \
	&& useradd -g docker -m -d $SERVICE_DATA -u 1040 $SERVICE_USER \
	&& apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --no-install-suggests -y \
	libsodium-dev \
	gosu \
	nano \
	procps \
	# Clean
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* \
	&& python3 -m pip install virtualenv --no-cache-dir \
	&& python3 -m virtualenv --python=/usr/local/bin/python3 $VIRTUAL_ENV

ENV PATH="$VIRTUAL_ENV/bin:$PATH"

COPY --from=builder /tmp/jm $SERVICE_DATA
COPY --from=builder /opt/venv /opt/venv
COPY entrypoint.sh /usr/local/bin/

WORKDIR /jm/scripts

ENTRYPOINT ["entrypoint.sh"]
CMD ["python", "joinmarketd.py"]
