#!/usr/bin/env bash
echo " * Updating binaries"
$(dirname "$0")/update_binaries.sh &>/dev/null

echo " * Bumping package version"
VER="$(modinfo -F version e100/lib/modules/*/kernel/net/wireguard.ko)"
sed -i "s/Version: .*/Version: $VER-1/" debian/control

echo " * Commiting changes"
git add debian/control **/lib **/usr
git commit -m "Bump package to version $VER"