SUMMARY = "U-Boot boot script for LS1046A OTA A/B boot with role rotation"
DESCRIPTION = "Compiles boot-ota.cmd into a U-Boot script image (.scr). \
The script loads shared-env FIT, computes core role via deterministic \
rotation, handles FIT A/B with rollback, and selects the correct rootfs slot."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS = "u-boot-mkimage-native"

SRC_URI = "file://boot-ota.cmd"

inherit deploy

do_compile() {
    mkimage -T script -C none -n "LS1046A OTA Boot" \
        -d ${WORKDIR}/boot-ota.cmd \
        ${B}/boot-ota.scr
}

do_deploy() {
    install -m 0644 ${B}/boot-ota.scr ${DEPLOYDIR}/boot-ota.scr
}

addtask deploy after do_compile
