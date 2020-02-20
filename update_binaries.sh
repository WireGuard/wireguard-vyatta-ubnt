#!/usr/bin/env bash
declare -A BOARDS
BOARDS[e50]=mipsel
BOARDS[e100]=mips
BOARDS[e200]=mips
BOARDS[e300]=mips
BOARDS[e1000]=mips
BOARDS[ugw3]=mips
BOARDS[ugw4]=mips
BOARDS[ugwxg]=mips

for board in "${!BOARDS[@]}"
do
	arch="${BOARDS[$board]}"

	echo "Downloading the wg util for $board..."
	curl -L -o "$board/usr/bin/wg" "https://build.lochnair.net/job/ubiquiti/job/wireguard/job/tools/lastSuccessfulBuild/artifact/wg-$arch"
	echo "Downloading the kernel module for $board..."
	modpath=$(find "$board" -name wireguard.ko)
	curl -L -o "$modpath" "https://build.lochnair.net/job/ubiquiti/job/wireguard/job/kmod-v1.10/lastSuccessfulBuild/artifact/wireguard-$board.ko"
	echo "Done."
done
