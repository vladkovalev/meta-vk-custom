SUMMARY = "OTA update agent for LS1046A A/B slot switching"
DESCRIPTION = "CLI tool for staging OTA updates: \
--fit writes FIT image to standby slot on per-core dedicated flash. \
--rootfs writes rootfs WIC to standby partition on shared flash (Master only). \
--env replaces the shared-env.itb FIT image. \
--full performs both FIT and rootfs update."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://ota-update.sh"

RDEPENDS:${PN} = "u-boot-fw-utils mtd-utils e2fsprogs bash core-role-manager"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/ota-update.sh ${D}${bindir}/ota-update
}
