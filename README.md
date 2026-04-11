# meta-vk-custom
cd /projects
mkdir yocto
cd yocto/
clone git://git.yoctoproject.org/poky
cd poky
source oe-init-build-env
git branch -r
git checkout scarthgap
git log
cd ..
git clone git://git.yoctoproject.org/meta-freescale
cd meta-freescale/
git checkout scarthgap
cd ..
git clone git://git.openembedded.org/meta-openembedded
cd meta-openembedded/
git checkout scarthgap
cd ..
source poky/oe-init-build-env bld_ls1046afrwy

bitbake core-image-minimal
bitbake linux-qoriq -c menuconfig
bitbake linux-qoriq -c compile -f
bitbake core-image-minimal

bitbake-layers show-layers
bitbake-layers add-layer /projects/yocto/meta-openembedded/meta-oe
bitbake-layers add-layer /projects/yocto/meta-openembedded/meta-python
bitbake-layers add-layer /projects/yocto/meta-openembedded/meta-networking
bitbake-layers create-layer meta-vk-custom
bitbake-layers show-layers

bitbake core-image-minimal-rootfsonly #serach for output tmp/deploy/images/ls1046afrwy
bitbake data-image
bitbake core-image-minimal-rootfs-data

