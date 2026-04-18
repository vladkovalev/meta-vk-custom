SUMMARY = "LS1046A OTA A/B image — shared rootfs for all cores"
DESCRIPTION = "Single rootfs image to be dd'd to the active or standby \
partition on shared eMMC/SD. Contains all OTA, role management, and \
health check services."

require recipes-core/images/core-image-minimal.bb

# Use the existing single-partition WKS — this image is dd'd to ONE slot
WKS_FILE = "rootfs-only.wks"
WKS_FILES = "rootfs-only.wks"
IMAGE_FSTYPES = "wic.bz2 ext4"

IMAGE_INSTALL:append = " \
    e2fsprogs-resize2fs \
    e2fsprogs-e2fsck \
    u-boot-fw-utils \
    ota-health-check \
    ota-update-agent \
    core-role-manager \
    util-linux \
    mtd-utils \
"
