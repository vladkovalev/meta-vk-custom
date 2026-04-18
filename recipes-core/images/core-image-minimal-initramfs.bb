SUMMARY = "Minimal initramfs for LS1046A OTA boot"
DESCRIPTION = "Small initramfs bundled in FIT image. Handles early boot: \
reads core identity, mounts correct rootfs slot, and pivots root."

IMAGE_INSTALL = " \
    busybox \
    base-files \
    initramfs-ota-init \
"

IMAGE_FSTYPES = "cpio.gz"

# Keep it small
IMAGE_LINGUAS = ""
NO_RECOMMENDATIONS = "1"

IMAGE_ROOTFS_SIZE = "8192"
IMAGE_ROOTFS_EXTRA_SPACE = "0"

inherit core-image
