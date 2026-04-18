SUMMARY = "Shared environment FIT image for LS1046A multi-core coordination"
DESCRIPTION = "Builds shared-env.itb — a FIT image containing the shared \
environment data used for boot cycle tracking, role override, and \
rootfs A/B slot coordination between all cores."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS = "u-boot-mkimage-native dtc-native"

SRC_URI = " \
    file://shared-env.its \
    file://shared-env.txt \
"

inherit deploy

do_compile() {
    cp ${WORKDIR}/shared-env.txt ${B}/
    cp ${WORKDIR}/shared-env.its ${B}/
    cd ${B}
    mkimage -f shared-env.its shared-env.itb
}

do_deploy() {
    install -m 0644 ${B}/shared-env.itb ${DEPLOYDIR}/shared-env.itb
}

addtask deploy after do_compile
