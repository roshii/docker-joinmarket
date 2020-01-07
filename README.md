# docker-joinmarket
joinmarket-clientserver in a container

## Prerequisite

- A bitcoincore node
- A tox proxy (optional)
- A valid `joinmarket.cfg`

## Usage example

### Start `joinmarketd`

```shell
docker run --name joinmarket --volume </local/path/to/jm>/joinmarket.cfg:/jm/scripts/joinmarket.cfg --volume </local/path/to/jm>/wallets:/jm/scripts/wallets r0shii/joinmarket joinmarket
```

### Edit yield-generator preferences.

```shell
docker exec -it joinmarket nano yg-privacyenhanced.py
```

### Start yield-generator

```shell
docker exec -it joinmarket python yg-privacyenhanced.py wallet.jmdat
```
You may exit container's shell using `Crt+P` `Ctrl+Q` control sequence.

### Stop yield-generator process

```shell
docker exec -it joinmarket kill -SIGTERM $(docker exec -it joinmarket ps -h | grep "yg-privacy" | cut -d" " -f1)
```
