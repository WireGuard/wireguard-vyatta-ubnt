# vyatta-wireguard

This is a Vyatta module and pre-built binaries for the Ubiquiti EdgeRouter
to support [WireGuard](https://www.wireguard.io/).

## Table of Contents
* [Installation](#installation)
* [Upgrade](#upgrade)
* [Uninstallation](#uninstallation)
* [Usage](#usage)
* [Routing](#routing)
* [Binaries](#binaries)
* [Packaging](#packaging)
* [Build from scratch](#build-from-scratch)

---

### Installation
Download the [latest release](https://github.com/Lochnair/vyatta-wireguard/releases) for your model and then install it via:
```bash
sudo dpkg -i wireguard-${BOARD}-${RELEASE}.deb
```

After you will have be able to create a `wireguard` interface (`show interfaces`).

---

### Upgrade
Download the [latest release](https://github.com/Lochnair/vyatta-wireguard/releases) for your model and then perform upgrade with:
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

### Uninstallation
#### Private key
Determine if the private key is stored as a file by running `show interfaces wireguard`; if the  `private key` line is a path then run the following command otherwise jump to [Remove the configuration](#remove-the-configuration)
```bash
sudo rm /config/auth/wg.key
```

#### Remove the configuration
```bash
configure

delete interfaces wireguard

commit
save
exit
```

#### Remove the package
```bash
sudo dpkg --remove wireguard
```
---

### Usage
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

### Routing
Currenty there is no integration between the routing daemon and WireGuard which means allowed-ips for a peer will not be updated based upon dynamic routing updates.

If you are going to utilize a dynamic routing protocol over wireguard interfaces it is recommended to configure them with a single peer per interface, disable route-allowed-ips and either configure allowed-ips to 0.0.0.0/0 or all ip addresses which might ever be routed over the interface including any multicast addresses required by the routing protocol.

---

### Binaries
This repository ships prebuilt binaries made from the [WireGuard source code](https://git.zx2c4.com/WireGuard/tree/src/).

The binaries are statically linked against [musl libc](https://www.musl-libc.org/) to mitigate potential issues with Ubiquiti EdgeOS's outdated glibc.

---

### Packaging
1. Clone the repo `git clone https://github.com/Lochnair/vyatta-wireguard`
2. Get the WireGuard version number from Lochnair's build server's latest successfully build from [build.lochnair.net/](https://build.lochnair.net/job/ubiquiti/job/wireguard-fw2.0/lastCompletedBuild/) (e.g. refs/tags/0.0.20181218)
3. Edit the verion number in `debian/control` to match the build server.
4. Run `./update_binaries.sh`
5. Run `make`
6. Get the newly created deb files from the `package` folder. 

---

### Build from scratch
If you are buliding from scratch, please be sure to use `-mabi=64` in your `CFLAGS` for compiling the userspace tools; otherwise there will be strange runtime errors.

#### Kernel Module
```bash
$ mkdir -p linux-src/linux-3.10
$ cd linux-src/linux-3.10
$ tar xf ../../source/kernel_*.tgz
$ cd ../..
$ tar xf source/cavm-executive_*.tgz
$ export KERNELDIR="$PWD/linux-src/linux-3.10/kernel"
$ cd OCTEON-SDK
$ . ./env-setup OCTEON_CN50XX --no-runtime-model --verbose
$ cd ..
$ export CROSS_COMPILE=mips64-octeon-linux-gnu-
$ export CC=mips64-octeon-linux-gnu-gcc
$ export ARCH=mips
$ make -C linux-src/linux-3.10/kernel -j$(nproc)
$ git clone https://git.zx2c4.com/WireGuard
$ make -C linux-src/linux-3.10/kernel M=$PWD/WireGuard/src modules -j$(nproc)
$ ls -l WireGuard/src/wireguard.ko
```

#### Userspace Tools
```bash
$ cd OCTEON-SDK
$ . ./env-setup OCTEON_CN50XX --no-runtime-model --verbose
$ cd ..
$ export CROSS_COMPILE=mips64-octeon-linux-gnu-
$ export CC=mips64-octeon-linux-gnu-gcc
$ export ARCH=mips
$ mkdir -p prefix
$ prefix="$PWD/prefix"
$ git clone git://git.musl-libc.org/musl
$ cd musl
$ CFLAGS=-mabi=64 ./configure --prefix="$prefix" --disable-shared
$ make -j$(nproc)
$ make install
$ cd ..
$ make -C linux-src/linux-3.10/kernel headers_install INSTALL_HDR_PATH="$prefix"
$ git clone git://git.netfilter.org/libmnl
$ cd libmnl
$ ./autogen.sh
$ CC="$prefix/bin/musl-gcc" CFLAGS=-mabi=64 ./configure --prefix="$prefix" --disable-shared --enable-static --host=x86_64-pc-linux-gnu
$ make -j$(nproc)
$ make install
$ cd ..
$ git clone https://git.zx2c4.com/WireGuard
$ CC="$prefix/bin/musl-gcc" make -C WireGuard/src/tools/ -j$(nproc)
$ ls -l WireGuard/src/tools/wg
```
