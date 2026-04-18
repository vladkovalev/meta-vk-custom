SUMMARY = "OTA initramfs init script for LS1046A"
DESCRIPTION = "Init script for the minimal initramfs. Parses core identity \
from kernel cmdline, finds the correct rootfs partition by label, and \
performs switch_root to the real rootfs."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://init"

RDEPENDS:${PN} = "busybox"

do_install() {
    install -d ${D}
    install -m 0755 ${WORKDIR}/init ${D}/init
}

FILES:${PN} = "/init"
