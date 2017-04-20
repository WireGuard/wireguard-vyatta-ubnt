# vyatta-wireguard

This is a vyatta module and pre-built binaries for the Ubiquiti EdgeRouter
to support [WireGuard](https://www.wireguard.io/).

### Installation

Download the latest `wireguard-octeon.deb` release (or build it yourself
here with `make`) and then install it via:

    $ sudo dpkg -i ./wireguard-octeon.deb

After you'll be able to have a `wireguard` section in `interfaces`.
