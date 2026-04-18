#!/bin/bash
# OTA Update Agent for LS1046A multi-core A/B system
# Usage:
#   ota-update --fit <fit-image>       Update this core's FIT (dedicated flash)
#   ota-update --rootfs <wic-image>    Write rootfs to standby slot (Master only)
#   ota-update --env <itb-file>        Replace shared-env.itb (Master only)
#   ota-update --full <fit> <rootfs>   Update both FIT and rootfs
set -euo pipefail

log() { logger -t "ota-update" "$1"; echo "$1"; }

# Load core identity
if [ -f /run/core-role.env ]; then
    . /run/core-role.env
else
    CORE_ID=1
    CORE_ROLE=master
fi

# Configurable MTD devices — override via environment or /etc/ota.conf
SHARED_ENV_MTD="${SHARED_ENV_MTD:-/dev/mtd3}"
SHARED_ENV_RUNTIME="/run/shared-env/env.txt"

# ── Shared env helpers ──
read_shared_env() {
    local key="$1"
    grep -oP "^${key}=\K.*" "$SHARED_ENV_RUNTIME" 2>/dev/null || echo ""
}

write_shared_env() {
    local key="$1" value="$2"
    if grep -q "^${key}=" "$SHARED_ENV_RUNTIME"; then
        sed -i "s/^${key}=.*/${key}=${value}/" "$SHARED_ENV_RUNTIME"
    else
        echo "${key}=${value}" >> "$SHARED_ENV_RUNTIME"
    fi
}

rebuild_shared_env_fit() {
    local TMPDIR
    TMPDIR=$(mktemp -d)
    cp "$SHARED_ENV_RUNTIME" "${TMPDIR}/shared-env.txt"

    # Use the ITS template from /etc if available, otherwise minimal inline
    if [ -f /etc/shared-env.its ]; then
        cp /etc/shared-env.its "${TMPDIR}/shared-env.its"
    else
        cat > "${TMPDIR}/shared-env.its" <<'ITSEOF'
/dts-v1/;
/ {
    description = "LS1046A Shared Environment";
    #address-cells = <1>;
    images {
        env {
            description = "Shared system environment";
            data = /incbin/("shared-env.txt");
            type = "firmware";
            arch = "arm64";
            compression = "none";
            hash-1 { algo = "sha256"; };
        };
    };
    configurations {
        default = "conf-1";
        conf-1 { description = "Shared env"; firmware = "env"; };
    };
};
ITSEOF
    fi

    cd "${TMPDIR}"
    mkimage -f shared-env.its shared-env.itb
    flash_erase "$SHARED_ENV_MTD" 0 0
    flashcp shared-env.itb "$SHARED_ENV_MTD"
    rm -rf "${TMPDIR}"
    log "Shared env FIT reflashed to ${SHARED_ENV_MTD}."
}

# ── FIT update (per-core dedicated flash) ──
update_fit() {
    local FIT_IMAGE="$1"

    if [ ! -f "$FIT_IMAGE" ]; then
        log "ERROR: FIT image not found: $FIT_IMAGE"
        exit 1
    fi

    local CURRENT_FIT
    CURRENT_FIT=$(fw_printenv -n fit_slot 2>/dev/null || echo "A")

    local TARGET_FIT
    if [ "$CURRENT_FIT" = "A" ]; then
        TARGET_FIT="B"
    else
        TARGET_FIT="A"
    fi

    # CORE_FIT_MTD should be set per-core (e.g., via /etc/ota.conf)
    local MTD_DEV="/dev/mtd${CORE_FIT_MTD:-1}"

    log "Core ${CORE_ID}: Staging FIT to slot ${TARGET_FIT} on ${MTD_DEV}"
    flash_erase "${MTD_DEV}" 0 0
    flashcp "$FIT_IMAGE" "${MTD_DEV}"

    fw_setenv fit_slot "$TARGET_FIT"
    fw_setenv fit_upgrade_available 1
    fw_setenv fit_boot_count 0
    fw_setenv fit_boot_confirmed 0
    log "Core ${CORE_ID}: FIT staged → slot ${TARGET_FIT}"
}

# ── RootFS update (shared flash, Master only) ──
update_rootfs() {
    local ROOTFS_IMAGE="$1"

    if [ "$CORE_ROLE" != "master" ]; then
        log "ERROR: Only Master can update shared rootfs. This core is ${CORE_ROLE}."
        exit 1
    fi

    if [ ! -f "$ROOTFS_IMAGE" ]; then
        log "ERROR: RootFS image not found: $ROOTFS_IMAGE"
        exit 1
    fi

    local CURRENT_SLOT
    CURRENT_SLOT=$(read_shared_env "ota_rootfs_slot")
    CURRENT_SLOT=${CURRENT_SLOT:-A}

    local TARGET_SLOT TARGET_DEV
    if [ "$CURRENT_SLOT" = "A" ]; then
        TARGET_SLOT="B"
        TARGET_DEV="/dev/mmcblk0p2"
    else
        TARGET_SLOT="A"
        TARGET_DEV="/dev/mmcblk0p1"
    fi

    log "Writing rootfs to standby slot ${TARGET_SLOT} (${TARGET_DEV})"
    dd if="$ROOTFS_IMAGE" of="$TARGET_DEV" bs=4M conv=fsync status=progress
    sync

    log "Running e2fsck on ${TARGET_DEV}..."
    e2fsck -f -y "$TARGET_DEV" || true

    write_shared_env "ota_rootfs_slot" "$TARGET_SLOT"
    write_shared_env "ota_rootfs_pending" "1"
    write_shared_env "ota_rootfs_confirmed" "0"
    rebuild_shared_env_fit

    log "Shared rootfs staged → slot ${TARGET_SLOT}"
}

# ── Shared env replace (Master only) ──
update_env() {
    local ENV_ITB="$1"

    if [ "$CORE_ROLE" != "master" ]; then
        log "ERROR: Only Master can update shared env."
        exit 1
    fi

    if [ ! -f "$ENV_ITB" ]; then
        log "ERROR: Shared env ITB not found: $ENV_ITB"
        exit 1
    fi

    log "Flashing new shared-env.itb to ${SHARED_ENV_MTD}"
    flash_erase "$SHARED_ENV_MTD" 0 0
    flashcp "$ENV_ITB" "$SHARED_ENV_MTD"
    log "Shared env FIT updated."
}

# ── CLI ──
case "${1:-}" in
    --fit)
        [ -n "${2:-}" ] || { echo "Usage: ota-update --fit <fit-image>"; exit 1; }
        update_fit "$2"
        ;;
    --rootfs)
        [ -n "${2:-}" ] || { echo "Usage: ota-update --rootfs <wic-image>"; exit 1; }
        update_rootfs "$2"
        ;;
    --env)
        [ -n "${2:-}" ] || { echo "Usage: ota-update --env <itb-file>"; exit 1; }
        update_env "$2"
        ;;
    --full)
        [ -n "${2:-}" ] && [ -n "${3:-}" ] || { echo "Usage: ota-update --full <fit-image> <wic-image>"; exit 1; }
        update_fit "$2"
        update_rootfs "$3"
        ;;
    *)
        echo "LS1046A OTA Update Agent"
        echo ""
        echo "Usage:"
        echo "  ota-update --fit <fit-image>          Update FIT on this core"
        echo "  ota-update --rootfs <wic-image>       Write rootfs to standby (Master only)"
        echo "  ota-update --env <itb-file>           Replace shared-env.itb (Master only)"
        echo "  ota-update --full <fit> <rootfs>      Update both FIT and rootfs"
        exit 1
        ;;
esac

log "==============================="
log "OTA staging complete. Reboot to activate."
log "==============================="
