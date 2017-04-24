# vyatta-wireguard

This is a Vyatta module and pre-built binaries for the Ubiquiti EdgeRouter
to support [WireGuard](https://www.wireguard.io/).

### Installation

Download the [latest `wireguard-octeon-${RELEASE}.deb` release](https://github.com/Lochnair/vyatta-wireguard/releases) (or build it yourself
here with `make`) and then install it via:

    $ sudo dpkg -i ./wireguard-octeon-${RELEASE}.deb

After you'll be able to have a `wireguard` section in `interfaces`.

### Usage

You can learn about how to actually use WireGuard on the
[website](https://www.wireguard.io/). All of the concepts translate
evenly here. Here's an example vyatta configuration:


```
interfaces {
    wireguard wg0 {
        private-key "iO3YxEZM5KNmdST1XYtv1xQ8AM3y12+/K+QFKY7rflw="
        address "192.168.33.1/24"
        listen-port 51820

        peer "aBaxDzgsyDk58eax6lt3CLedDt6SlVHnDxLG2K5UdV4=" {
            allowed-ips "192.168.33.101/32"
            endpoint "example1.example.net:51820"
        }
        peer "GIPWDet2eswjz1JphYFb51sh6I+CwvzOoVyD7z7kZVc=" {
            allowed-ips "192.168.33.102/32,192.168.33.103/32"
            endpoint "anotherexample.example.org:29922"
        }
    }
}
```

If you prefer not to put private keys in the config file, the `private-key` and `preshared-key` items can alternatively take a file path on the filesystem, such as one in `/config/auth/`.

### Binaries

This repository ships prebuilt binaries, made from the [WireGuard source code](https://git.zx2c4.com/WireGuard/tree/src/). If you're buliding from scratch, please be sure to use `-mabi=64` in your `CFLAGS` for compiling the userspace tools; otherwise there will be strange runtime errors. The binaries in this repository are statically linked against [musl libc](https://www.musl-libc.org/) to mitigate potential issues with Ubiquiti's outdated libc.
