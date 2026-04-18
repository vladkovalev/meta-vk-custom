SUMMARY = "Factory provisioning image — creates A/B rootfs layout on shared eMMC"
DESCRIPTION = "Used ONCE at factory to prepare shared flash with two rootfs \
partitions (A active, B standby) and a shared environment partition. \
After provisioning, OTA updates write to individual partitions."

require recipes-core/images/core-image-minimal.bb

WKS_FILE = "factory-provision.wks"
WKS_FILES = "factory-provision.wks"
IMAGE_FSTYPES = "wic.bz2"

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
