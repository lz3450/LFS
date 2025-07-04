efibootmgr --create --disk /dev/nvme0n1 --part 1 --label "Arch Linux" --loader /vmlinuz-linux --unicode "root=UUID= rw initrd=/intel-ucode.img initrd=/initramfs-linux.img" --verbose
