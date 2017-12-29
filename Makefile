all: deb-e300 deb-octeon deb-ralink

clean:
	rm -rf package
deb-e300: clean
	mkdir -p package/scratch
	tar --owner=root:0 --group root:0 -czf package/scratch/data.tar.gz -C generic . -C ../e300 .
	tar --owner=root:0 --group root:0 -czf package/scratch/control.tar.gz -C debian .
	echo 2.0 > package/scratch/debian-binary
	ar -rcs package/$(shell sed -n 's/Version: \(.*\)/wireguard-e300-\1.deb/p' debian/control) package/scratch/debian-binary package/scratch/data.tar.gz package/scratch/control.tar.gz
	rm -rf package/scratch
deb-octeon: clean
	mkdir -p package/scratch
	tar --owner=root:0 --group root:0 -czf package/scratch/data.tar.gz -C generic . -C ../octeon .
	tar --owner=root:0 --group root:0 -czf package/scratch/control.tar.gz -C debian .
	echo 2.0 > package/scratch/debian-binary
	ar -rcs package/$(shell sed -n 's/Version: \(.*\)/wireguard-octeon-\1.deb/p' debian/control) package/scratch/debian-binary package/scratch/data.tar.gz package/scratch/control.tar.gz
	rm -rf package/scratch
deb-ralink: clean
	mkdir -p package/scratch
	tar --owner=root:0 --group root:0 -czf package/scratch/data.tar.gz -C generic . -C ../ralink .
	cp -a debian package/scratch/
	sed -i "s/Architecture: .*/Architecture: mipsel/" package/scratch/debian/control
	tar --owner=root:0 --group root:0 -czf package/scratch/control.tar.gz -C package/scratch/debian .
	echo 2.0 > package/scratch/debian-binary
	ar -rcs package/$(shell sed -n 's/Version: \(.*\)/wireguard-ralink-\1.deb/p' debian/control) package/scratch/debian-binary package/scratch/data.tar.gz package/scratch/control.tar.gz
	rm -rf package/scratch
