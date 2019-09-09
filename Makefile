TAR ?= tar
AR ?= ar

all: deb-e50 deb-e100 deb-e200 deb-e300 deb-e1000 deb-ugw3 deb-ugw4 deb-ugwxg

clean:
	rm -rf package

define gen_deb
	mkdir -p package/scratch
        $(TAR) --owner=root:0 --group root:0 -czf package/scratch/data.tar.gz -C generic . -C ../$(1) .
	cp -a debian package/scratch/
	sed -i "s/Architecture: .*/Architecture: $(2)/" package/scratch/debian/control
	sed -i "s@KERNEL_VER@$$(find $(1)/lib/modules/ -maxdepth 1 -mindepth 1 -type d -printf "%f\n")@g" package/scratch/debian/preinst
        $(TAR) --owner=root:0 --group root:0 -czf package/scratch/control.tar.gz -C package/scratch/debian .
        echo 2.0 > package/scratch/debian-binary
        $(AR) -rcs package/$(shell sed -n 's/Version: \(.*\)/wireguard-$(1)-\1.deb/p' debian/control) package/scratch/debian-binary package/scratch/control.tar.gz package/scratch/data.tar.gz
        rm -rf package/scratch
endef

deb-e50: clean
	$(call gen_deb,e50,mipsel)

deb-e100: clean
	$(call gen_deb,e100,mips)

deb-e200: clean
	$(call gen_deb,e200,mips)

deb-e300: clean
	$(call gen_deb,e300,mips)

deb-e1000: clean
	$(call gen_deb,e1000,mips)

deb-ugw3: clean
	$(call gen_deb,ugw3,mips)

deb-ugw4: clean
	$(call gen_deb,ugw4,mips)

deb-ugwxg: clean
	$(call gen_deb,ugwxg,mips)
