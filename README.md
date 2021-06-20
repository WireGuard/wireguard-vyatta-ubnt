WireGuard for Ubiquiti
======================

This repository contains Vyatta configuration files to integrate WireGuard with Ubiquiti Networks devices.

Please see below for instructions on how to install the prebuilt deb packages listed under [releases](https://github.com/WireGuard/wireguard-vyatta-ubnt/releases).

Table of Contents
-----------------

* [Installation](#installation)
* [Upgrade](#upgrade)
* [Uninstallation](#uninstallation)
* [Usage](#usage)
* [Routing](#routing)
* [Binaries](#binaries)
* [Persistence on Reboot on USG](#persistence-on-reboot-on-usg)

---

Installation
------------

Download the [latest release](https://github.com/WireGuard/wireguard-vyatta-ubnt/releases/latest) for your model and then install it:

```bash
curl -OL https://github.com/WireGuard/wireguard-vyatta-ubnt/releases/download/${RELEASE}/${BOARD}-${RELEASE}.deb

sudo dpkg -i ${BOARD}-${RELEASE}.deb
```

After you will have be able to create a `wireguard` interface (`show interfaces`).

---

Upgrade
-------

Download the [latest release](https://github.com/WireGuard/wireguard-vyatta-ubnt/releases/latest) for your model and then perform upgrade:

```bash
curl -OL https://github.com/WireGuard/wireguard-vyatta-ubnt/releases/download/${RELEASE}/${BOARD}-${RELEASE}.deb

configure
set interfaces wireguard wg0 route-allowed-ips false
commit
delete interfaces wireguard
commit
sudo rmmod wireguard
sudo dpkg -i ${BOARD}-${RELEASE}.deb
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

Read the documentation on [WireGuard.com](https://www.wireguard.com/) for general WireGuard concepts. Here is a simple example of a configuration for Vyatta/EdgeOS:

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

The `private-key` and `preshared-key` fields can take the key value or a file path. So if you prefer not to put the keys in the config file, then the `private-key` and `preshared-key` field can alternatively take a file path on the filesystem, such as `/config/auth/key`.

---

Routing
-------

Currenty there is no integration between the routing daemon and WireGuard which means allowed-ips for a peer will not be updated based upon dynamic routing updates.

If you are going to utilize a dynamic routing protocol over wireguard interfaces it is recommended to configure them with a single peer per interface, disable route-allowed-ips and either configure allowed-ips to 0.0.0.0/0 or all ip addresses which might ever be routed over the interface including any multicast addresses required by the routing protocol.

---

Binaries
--------

Prebuilt binaries are available under [releases](https://github.com/WireGuard/wireguard-vyatta-ubnt/releases).

The binaries are statically linked against [musl libc](https://www.musl-libc.org/) to mitigate potential issues with Ubiquiti EdgeOS's outdated glibc.

---

Persistence on Reboot on USG
----------------------------

On the USG3/4 Pro the commandline setup above does not survive reboot/re-provisioning. The settings need to be added to a `config.gateway.json` file and placed on the *controller*. Depending on your particular setup, this file can be located in several locations. You can use the *commented* example below and follow the instructions in [Unifi - USG Advanced Configuration Using config.gateway.json](https://help.ui.com/hc/en-us/articles/215458888-UniFi-USG-Advanced-Configuration-Using-config-gateway-json) to create the file in the appropriate location. The firewall changes can be made in the UI, or added to the file.

```json
{
  "firewall": {
    "name": {
      "WAN_LOCAL": {
        "rule": {
          "20": {
            "action": "accept",
            "description": "WireGuard",
            "destination": {
                    "port": "51820" //Firewall port - can be customised, adjust listen port accordingly
            },
            "protocol": "udp"
          }
        }
      }
    },
    "group": {
      "network-group": {
        "remote_user_vpn_network": {
          "description": "Remote User VPN subnets",
          "network": [
            "10.16.1.0/24"  //Subnet assigned to wireguard clients
          ]
        }
      }
    }
  },
  "interfaces": {
    "wireguard": {
      "wg0": {
        "address": [
          "10.16.1.1/24"  //USG gateway address in wireguard subnet
        ],
        "firewall": {
          "in": {
            "name": "LAN_IN"
          },
          "local": {
            "name": "LAN_LOCAL"
          },
          "out": {
            "name": "LAN_OUT"
          }
        },
        "listen-port": "51820",  //Listen port - can be customised, adjust firewall port accordingly
        "mtu": "1500",
        "peer": [{
          "wZ0j/CM/nJ6tdIxFTtBLOxbIoTNoK0Tjn49rZgasLUM=": {   //Peer 1 Public Key
            "allowed-ips": [
              "10.16.1.50/32"               //Peer IP address
            ],
            "persistent-keepalive": 25
          }
        },
        {
          "wZ0j/CM/nJ6tdIxFTtBLOxbIoTNoK0Tjn49rZgasLUM=": {   //Peer 2 public key
            "allowed-ips": [
              "10.16.1.51/32"
            ],
            "persistent-keepalive": 25
          }
        },
        {
          "wZ0j/CM/nJ6tdIxFTtBLOxbIoTNoK0Tjn49rZgasLUM=": {   //Peer 3 public key
            "allowed-ips": [
              "10.16.1.52/32"
            ],
            "persistent-keepalive": 25
          }
        },
        {
          "wZ0j/CM/nJ6tdIxFTtBLOxbIoTNoK0Tjn49rZgasLUM=": {   //Peer 4 public key
            "allowed-ips": [
              "10.16.1.53/32"
            ],
            "persistent-keepalive": 25
          }
        },
        {
          "wZ0j/CM/nJ6tdIxFTtBLOxbIoTNoK0Tjn49rZgasLUM=": {  //Peer 5 public key
            "allowed-ips": [
              "10.16.1.54/32"
            ],
            "persistent-keepalive": 25
          }
        }],
        "private-key": "/config/auth/wireguard/wg_private.key",  //Server key
        "route-allowed-ips": "true"
      }
    }
  }
}
```
---
