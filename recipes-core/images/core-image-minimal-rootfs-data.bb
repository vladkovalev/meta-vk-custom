require recipes-core/images/core-image-minimal.bb

#Ensure WIC can find wks files from this layer
#WKS_SEARCH_PATH:append = ":${LAYERDIR}/recipes-core/images/wic/"

#Use the single-partition layout
WKS_FILE = "rootfs-data.wks"
WKS_FILES = "rootfs-data.wks"
#WKS_FILE = "/projects/yocto/meta-vk-custom/recipes-core/images/wic/rootfs-only.wks"
#WKS_FILES = "/projects/yocto/meta-vk-custom/recipes-core/images/wic/rootfs-only.wks"
IMAGE_FSTYPES = "wic.bz2"
IMAGE_INSTALL:append = " e2fsprogs-resize2fs e2fsprogs-e2fsck" 
