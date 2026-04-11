SUMMARY = "Standalone data parition WIC image" 
LICENSE = "MIT"
inherit core-image 
IMAGE_INSTALL = ""
IMAGE_LINGUALS = ""

#Ensure WIC can find wks files from this layer
#WKS_SEARCH_PATH:append = ":${LAYERDIR}/recipes-core/images/"

#Use the single-partition layout
WKS_FILE = "data-only.wks"
WKS_FILES = "data-only.wks"
IMAGE_FSTYPES = "wic.bz2"
