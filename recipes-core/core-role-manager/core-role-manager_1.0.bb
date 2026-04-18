SUMMARY = "Determines and exports core role (Master/Slave/Backup) at runtime"
DESCRIPTION = "Systemd service that parses core identity from kernel cmdline \
(vk.core_id, vk.core_role, vk.boot_cycle, vk.fit_slot, vk.rootfs_slot) \
and exports them to /run/core-role.env for other services to consume."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://core-role-manager.sh \
    file://core-role-manager.service \
    file://core-role.conf.template \
"

RDEPENDS:${PN} = "bash"

inherit systemd

SYSTEMD_SERVICE:${PN} = "core-role-manager.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/core-role-manager.sh ${D}${bindir}/core-role-manager

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/core-role-manager.service ${D}${systemd_system_unitdir}/

    install -d ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/core-role.conf.template ${D}${sysconfdir}/core-role.conf
}
