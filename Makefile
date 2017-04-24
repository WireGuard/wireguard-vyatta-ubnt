all: deb

clean:
	rm -rf package
deb: clean
	mkdir -p package/scratch
	tar --owner=root:0 --group root:0 -czf package/scratch/data.tar.gz -C generic . -C ../octeon .
	tar --owner=root:0 --group root:0 -czf package/scratch/control.tar.gz -C debian .
	echo 2.0 > package/scratch/debian-binary
	ar -rcs package/$(shell sed -n 's/Version: \(.*\)/wireguard-octeon-\1.deb/p' debian/control) package/scratch/debian-binary package/scratch/data.tar.gz package/scratch/control.tar.gz
	rm -rf package/scratch
