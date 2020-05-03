WireGuard for Ubiquiti
======================

This repository contains the vyatta configuration files to integrate WireGuard with Ubiquiti Networks devices.

Please see below for instructions on how to install the prebuilt deb packages listed under [releases](https://github.com/WireGuard/wireguard-vyatta-ubnt/releases).

Table of Contents
-----------------

* [Installation](#installation)
* [Upgrade](#upgrade)
* [Uninstallation](#uninstallation)
* [Usage](#usage)
* [Routing](#routing)
* [Binaries](#binaries)
* [Build from scratch](#build-from-scratch)

---

Installation
------------

Download the [latest release](https://github.com/WireGuard/wireguard-vyatta-ubnt/releases) for your model and then install it via:

```bash
sudo dpkg -i wireguard.deb
```

After you will have be able to create a `wireguard` interface (`show interfaces`).

---

Upgrade
-------

Download the [latest release](https://github.com/WireGuard/wireguard-vyatta-ubnt/releases) for your model and then perform upgrade with:

```bash
configure
set interfaces wireguard wg0 route-allowed-ips false
commit
delete interfaces wireguard
commit
sudo rmmod wireguard
sudo dpkg -i /path/to/wireguard-${BOARD}-${RELEASE}.deb
sudo modprobe wireguard
load
commit
exit
```

This allows the upgrade without reboot.

---

Uninstallation
--------------

### Private key ###

Determine if the private key is stored as a file by running `show interfaces wireguard`; if the  `private key` line is a path then run the following command otherwise jump to [Remove the configuration](#remove-the-configuration)

```bash
sudo rm /config/auth/wg.key
```

### Remove the configuration ###

```bash
configure

delete interfaces wireguard

commit
save
exit
```

### Remove the package ###

```bash
sudo dpkg --remove wireguard
```

---

Usage
-----

You can learn about how to actually use WireGuard on [WireGuard.com](https://www.wireguard.com/).  All of the concepts are explained in depth..

Here is a simple example of a configuration for vyatta/EdgeOS:

```bash
wg genkey | tee /config/auth/wg.key | wg pubkey >  wg.public

configure

set interfaces wireguard wg0 address 192.168.33.1/24
set interfaces wireguard wg0 listen-port 51820
set interfaces wireguard wg0 route-allowed-ips true

set interfaces wireguard wg0 peer GIPWDet2eswjz1JphYFb51sh6I+CwvzOoVyD7z7kZVc= endpoint example1.org:29922
set interfaces wireguard wg0 peer GIPWDet2eswjz1JphYFb51sh6I+CwvzOoVyD7z7kZVc= allowed-ips 192.168.33.101/32

set interfaces wireguard wg0 peer aBaxDzgsyDk58eax6lt3CLedDt6SlVHnDxLG2K5UdV4= endpoint example2.net:51820
set interfaces wireguard wg0 peer aBaxDzgsyDk58eax6lt3CLedDt6SlVHnDxLG2K5UdV4= allowed-ips 192.168.33.102/32
set interfaces wireguard wg0 peer aBaxDzgsyDk58eax6lt3CLedDt6SlVHnDxLG2K5UdV4= allowed-ips 192.168.33.103/32

set interfaces wireguard wg0 private-key /config/auth/wg.key

set firewall name WAN_LOCAL rule 20 action accept
set firewall name WAN_LOCAL rule 20 protocol udp
set firewall name WAN_LOCAL rule 20 description 'WireGuard'
set firewall name WAN_LOCAL rule 20 destination port 51820

commit
save
exit
```

The `private-key` and `preshared-key` fields can take the key value or a file path.

So if  you prefer not to put the keys in the config file, then the `private-key` and `preshared-key` field can alternatively take a file path on the filesystem, such as `/config/auth/`.

---

Routing
-------

Currenty there is no integration between the routing daemon and WireGuard which means allowed-ips for a peer will not be updated based upon dynamic routing updates.

If you are going to utilize a dynamic routing protocol over wireguard interfaces it is recommended to configure them with a single peer per interface, disable route-allowed-ips and either configure allowed-ips to 0.0.0.0/0 or all ip addresses which might ever be routed over the interface including any multicast addresses required by the routing protocol.

---

Binaries
--------

Prebuild binaries are available under [releases](https://github.com/WireGuard/wireguard-vyatta-ubnt/releases)

The binaries are statically linked against [musl libc](https://www.musl-libc.org/) to mitigate potential issues with Ubiquiti EdgeOS's outdated glibc.

Building from scratch
---------------------

There is currently no build script available. Please use the CI files as a reference for now.
