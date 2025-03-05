
BUSYBOX_DIR		= busybox-1.37.0
TARBALL			= $(BUSYBOX_DIR).tar.bz2
BUSYBOX_URL		= https://busybox.net/downloads/

INITRD_IMG		= initrd.img

$(BUSYBOX_DIR):
	@if [ ! -d "$(BUSYBOX_DIR)" ]; then \
		echo "Directory $(BUSYBOX_DIR) not found. Downloading BusyBox"; \
		wget $(BUSYBOX_URL)$(TARBALL) -O $(TARBALL) || exit 1; \
		tar -xjf $(TARBALL) || exit 1; \
		rm -f $(TARBALL); \
	else \
		echo "Directory $(BUSYBOX_DIR) exists. Skipping download."; \
	fi

busybox: $(BUSYBOX_DIR)
	cp busybox.config $(BUSYBOX_DIR)/.config
	make -C $(BUSYBOX_DIR) -j$(nproc)
	cp $(BUSYBOX_DIR)/busybox .

$(INITRD_IMG): busybox
	mkdir initramfs
	cd initramfs && mkdir -p bin sbin etc proc sys usr/bin usr/sbin dev
	
	cp busybox initramfs/bin/
	cp create_symlinks.sh initramfs/bin/
	cd initramfs/bin/ && ./create_symlinks.sh
	
	cp init initramfs/init
	chmod +x initramfs/init
	sudo mknod -m 600 initramfs/dev/console c 5 1
	sudo mknod -m 666 initramfs/dev/null c 1 3
	
	cd initramfs && \
	find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../initrd.img

fs: $(INITRD_IMG)

clean:
	rm -rf initramfs

qemu: fs
	qemu-system-x86_64 \
	-kernel "bzImage" \
	-initrd "$(INITRD_IMG)" \
	-append "console=ttyS0 init=/init" \
	-nographic

.PHONY: fs clean qemu