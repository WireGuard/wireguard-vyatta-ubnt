#!/bin/sh
# This script loads the wireguard module and copies the wireguard tools.
# The built-in kernel module will be loaded if it exists.
WIREGUARD="$(cd "$(dirname "$0")" && pwd -P)"

# create symlinks to wireguard tools
ln -sf $WIREGUARD/tools/wg-quick /usr/bin
ln -sf $WIREGUARD/tools/wg /usr/bin
ln -sf $WIREGUARD/tools/qrencode /usr/bin
if [ ! -x "$(command -v bash)" ]; then
	ln -sf $WIREGUARD/tools/bash /bin
fi
if [ ! -x "$(command -v resolvconf)" ]; then
	ln -sf $WIREGUARD/tools/resolvconf /sbin
	if [ ! -f "/etc/resolvconf.conf" ]
	then
	   ln -sf $WIREGUARD/etc/resolvconf.conf /etc
	fi
fi

# create symlink to wireguard config folder
mkdir -p $WIREGUARD/etc/wireguard
if [ ! -d "/etc/wireguard" ]
then
   ln -sf $WIREGUARD/etc/wireguard /etc/wireguard
fi

# required by wg-quick
if [ ! -d "/dev/fd" ]
then
   ln -s /proc/self/fd /dev/fd
fi

#load dependent modules
modprobe udp_tunnel
modprobe ip6_udp_tunnel

lsmod|egrep ^wireguard > /dev/null 2>&1
if [ $? -eq 1 ]
then
   ver=`uname -r`
   echo "loading wireguard..."
   if [ -e /lib/modules/$ver/extra/wireguard.ko ]; then
      modprobe wireguard
   elif [ -e $WIREGUARD/modules/wireguard-$ver.ko ]; then
     insmod $WIREGUARD/modules/wireguard-$ver.ko
#    iptable_raw required for wg-quick's use of iptables-restore
     insmod $WIREGUARD/modules/iptable_raw-$ver.ko
     insmod $WIREGUARD/modules/ip6table_raw-$ver.ko
   else
     echo "Unsupported Kernel version $ver"
   fi
fi
