SUMMARY = "Standalone per-core data partition WIC image"
DESCRIPTION = "Empty data partition for each core's dedicated flash. \
Persistent across OTA updates — never overwritten by the update agent."
LICENSE = "MIT"

inherit core-image

IMAGE_INSTALL = ""
IMAGE_LINGUAS = ""

WKS_FILE = "data-core.wks"
WKS_FILES = "data-core.wks"
IMAGE_FSTYPES = "wic.bz2"
