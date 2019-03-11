# Proxmox docker

This repository contains a Docker container for virtualizing Proxmox
using QEMU. It uses high-performance QEMU options (KVM, and TAP network driver).
It currently only supports macvlan networks. Bridge mode is next on the list.

This currently only works for x86_64 architectures.

# Heavely rewritten to support macvlan(s)

Be sure to append `-o macvlan_mode=passthru` option when creating  the macvlan else the VMs won't
be able to communicate with your router

## Using the container

Via `docker run`:

```bash
$ docker build -t proxmox-docker .
$ docker run --rm -it \
    --device=/dev/kvm:/dev/kvm --device=/dev/net/tun:/dev/net/tun \
    --cap-add NET_ADMIN -v $VM_IMAGE_FILE:/image \
    proxmox-docker
```

Via `docker-compose.yml`:

```yaml
version: "3"
services:
    proxmox:
        build:
          context: .
        cap_add:
            - NET_ADMIN
        devices:
            - /dev/net/tun
            - /dev/kvm
        volumes:
            - ${VM_IMAGE:?VM image must be supplied}:/image
        restart: always
```

## Interaction

To interact with proxmox if started with `docker compose up -d`:

```docker attach ${container_name}```

All signals will be proxied to the container, to detach you must ctrl-p, ctrl-q. [Docker docs](https://docs.docker.com/reference/cli/docker/container/attach/)

## Tips 

* You can quit the VM (when attached to the container) by entering the special
  key sequence `C-a x`. Killing the docker container will also shut down the
  VM.

## Caveat Emptor

* VMs will not be able to resolve container-names on user-defined bridges.
  This is due to the way Docker's "Embedded DNS" server works. VMs can still
  connect to other containers on the same bridge using IP addresses.

## Credits

Based on: [jkz0/qemu](https://hub.docker.com/r/jkz0/qemu)
