#!/bin/bash
# Parse core identity from kernel cmdline and export to /run/core-role.env
# Other services source this file to determine their role.
set -euo pipefail

CMDLINE=$(cat /proc/cmdline)

extract_param() {
    echo "$CMDLINE" | grep -oP "${1}=\K[^ ]+" || echo ""
}

CORE_ID=$(extract_param "vk.core_id")
CORE_ROLE=$(extract_param "vk.core_role")
BOOT_CYCLE=$(extract_param "vk.boot_cycle")
FIT_SLOT=$(extract_param "vk.fit_slot")
ROOTFS_SLOT=$(extract_param "vk.rootfs_slot")

# Defaults for single-core or missing params
CORE_ID=${CORE_ID:-1}
CORE_ROLE=${CORE_ROLE:-master}
BOOT_CYCLE=${BOOT_CYCLE:-0}

cat > /run/core-role.env <<EOF
CORE_ID=${CORE_ID}
CORE_ROLE=${CORE_ROLE}
BOOT_CYCLE=${BOOT_CYCLE}
FIT_SLOT=${FIT_SLOT}
ROOTFS_SLOT=${ROOTFS_SLOT}
EOF

chmod 0644 /run/core-role.env
cp /run/core-role.env /etc/core-role.conf

logger -t "core-role-manager" "Core ${CORE_ID} booted as ${CORE_ROLE} (cycle=${BOOT_CYCLE}, fit=${FIT_SLOT}, rootfs=${ROOTFS_SLOT})"
echo "Core ${CORE_ID} = ${CORE_ROLE}"
