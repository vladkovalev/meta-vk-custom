# LS1046A FIT image configuration
# Include in local.conf: require conf/machine/ls1046a-fitimage.inc
#
# Overrides default KERNEL_IMAGETYPE=Image from qoriq-arm64.inc
# to produce a FIT image containing kernel + DTB + initramfs.

KERNEL_IMAGETYPE = "fitImage"
KERNEL_CLASSES += "kernel-fitimage"

# Initramfs as a separate FIT node (not bundled into kernel binary)
# U-Boot loads kernel, DTB, and ramdisk independently from the FIT
INITRAMFS_IMAGE = "core-image-minimal-initramfs"
INITRAMFS_IMAGE_BUNDLE = "0"

# LS1046A memory map load addresses
UBOOT_ARCH = "arm64"
UBOOT_ENTRYPOINT = "0x80080000"
UBOOT_LOADADDRESS = "0x80080000"
UBOOT_DTB_LOADADDRESS = "0x90000000"
UBOOT_RD_LOADADDRESS = "0xa0000000"
UBOOT_RD_ENTRYPOINT = "0xa0000000"

# FIT metadata
FIT_DESC = "LS1046A OTA FIT Image"
FIT_GENERATE_KEYS ?= "0"
