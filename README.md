# meta-vk-custom
This repo contains Yocto 5.0 (scarthgap) custom layer
for NXP  NXP LS1046A Freeway Board  
See [LS1046A Freeway Board](https://privateisland.tech/dev/yocto-frwy-ls1046a)  
**This project is working under Ubuntu 24.04**
## Check out the GIT repo's 
```bash
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
```
Modify our "conf/local.conf" file to set MACHINE="ls1046afrwy"  
Add "/build/yocto/meta-freescale" to "conf/bblayers.conf".  
`bitbake-layers add-layer /projects/yocto/meta-freescale`  
Try to build  
`bitbake core-image-minimal`  
Unfortunately, we ran into an error while compiling linux-qoriq. Disable the MXC GPU driver (MXC_GPU_VIV) in the kernel and rebuild.
```
bitbake linux-qoriq -c menuconfig
bitbake linux-qoriq -c compile -f
bitbake core-image-minimal
```
# Add custom layer 
```
bitbake-layers show-layers
bitbake-layers add-layer /projects/yocto/meta-openembedded/meta-oe
bitbake-layers add-layer /projects/yocto/meta-openembedded/meta-python
bitbake-layers add-layer /projects/yocto/meta-openembedded/meta-networking
clone git://github.com/vladkovalev/meta-vk-custom

#bitbake-layers create-layer meta-vk-custom
bitbake-layers show-layers
```
## Build artifacts
```bitbake core-image-minimal-rootfsonly
bitbake data-image
bitbake core-image-minimal-rootfs-data
```
## possible u_boot args values
```bash
setenv bootargs 'console=ttyS0,115200 root=/dev/ram0 earlycon=uart8250,mmio,0x21c0500 mtdparts=1550000.spi:1m(rcw),15m(u-boot),48m(kernel.itb);7e800000.flash:16m(nand_uboot),48m(nand_kernel),448m(nand_free)'
setenv bootargs 'console=ttyS0,115200 root=LABEL=rootfs rootfstype=ext4 rootwait rw earlycon=uart8250,mmio,0x21c0500 mtdparts=1550000.spi:1m(rcw),15m(u-boot),48m(kernel.itb);7e800000.flash:16m(nand_uboot),48m(nand_kernel),448m(nand_free)'
setenv bootargs_label  'root=LABEL=rootfs rootfstype=ext4 rootwait rw'
setenv bootargs_direct 'root=/dev/mmcblk0p1 rootfstype=ext4 rootwait rw'

# To use label:
setenv bootargs "${bootargs_label}"
```
# Include FIT image config in local.conf
```bash
echo 'require conf/machine/ls1046a-fitimage.inc' >> conf/local.conf
```
## Build artifacts
```bash
bitbake core-image-ota              # → rootfs.wic.bz2 + rootfs.ext4
bitbake factory-provision-image      # → A/B partitioned eMMC (factory only)
bitbake shared-env-image             # → shared-env.itb
bitbake data-image-core              # → per-core data partition
bitbake u-boot-boot-script           # → boot-ota.scr
bitbake virtual/kernel               # → fitImage (kernel + dtb + initramfs)
```
