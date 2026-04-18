SUMMARY = "OTA boot health-check and confirmation service"
DESCRIPTION = "Systemd service that validates boot health after OTA update. \
Role-aware: Master confirms shared rootfs for all cores, each core confirms \
its own FIT independently. On failure, triggers reboot for U-Boot rollback."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://ota-health-check.sh \
    file://ota-health-check.service \
    file://fw_env.config \
"

RDEPENDS:${PN} = "u-boot-fw-utils bash core-role-manager"

inherit systemd

SYSTEMD_SERVICE:${PN} = "ota-health-check.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/ota-health-check.sh ${D}${bindir}/ota-health-check

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/ota-health-check.service ${D}${systemd_system_unitdir}/

    install -d ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/fw_env.config ${D}${sysconfdir}/fw_env.config
}
