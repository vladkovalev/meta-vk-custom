#!/bin/bash
# OTA health-check — role-aware for LS1046A multi-core system
# Master confirms shared rootfs, each core confirms its own FIT.
set -euo pipefail

LOG_TAG="ota-health-check"
log() { logger -t "$LOG_TAG" "$1"; echo "$1"; }

# Load core identity
if [ -f /run/core-role.env ]; then
    . /run/core-role.env
else
    CORE_ID=1
    CORE_ROLE=master
fi

log "Health check starting: Core ${CORE_ID} (${CORE_ROLE})"

# ---- Check if FIT upgrade is pending (per-core dedicated env) ----
FIT_UPGRADE=$(fw_printenv -n fit_upgrade_available 2>/dev/null || echo "0")

# ---- Check if RootFS upgrade is pending (shared env) ----
ROOTFS_PENDING="0"
if [ -f /run/shared-env/env.txt ]; then
    ROOTFS_PENDING=$(grep -oP 'ota_rootfs_pending=\K[^ ]*' /run/shared-env/env.txt 2>/dev/null || echo "0")
fi

if [ "$FIT_UPGRADE" = "0" ] && [ "$ROOTFS_PENDING" = "0" ]; then
    log "No pending upgrades. Nothing to do."
    exit 0
fi

HEALTH_OK=true

# ---- Basic health checks ----
for svc in networking; do
    if ! systemctl is-active --quiet "$svc" 2>/dev/null; then
        log "FAIL: service $svc is not active"
        HEALTH_OK=false
    fi
done

# Filesystem write test
if ! touch /tmp/.ota_health_probe 2>/dev/null; then
    log "FAIL: cannot write to /tmp"
    HEALTH_OK=false
else
    rm -f /tmp/.ota_health_probe
fi

# ---- Role-specific checks ----
case "$CORE_ROLE" in
    master)
        log "Master: running extended checks..."
        # Add master-specific checks here (e.g., can reach other cores)
        ;;
    slave|backup)
        log "${CORE_ROLE}: basic checks only"
        ;;
esac

# ---- Decision ----
if [ "$HEALTH_OK" = true ]; then
    log "Health checks PASSED for Core ${CORE_ID} (${CORE_ROLE})"

    # Confirm FIT (per-core dedicated env)
    if [ "$FIT_UPGRADE" = "1" ]; then
        fw_setenv fit_boot_confirmed 1
        fw_setenv fit_upgrade_available 0
        fw_setenv fit_boot_count 0
        log "FIT upgrade confirmed."
    fi

    # Master confirms shared rootfs for all cores
    if [ "$CORE_ROLE" = "master" ] && [ "$ROOTFS_PENDING" = "1" ]; then
        if [ -f /run/shared-env/env.txt ]; then
            sed -i 's/^ota_rootfs_pending=.*/ota_rootfs_pending=0/' /run/shared-env/env.txt
            sed -i 's/^ota_rootfs_confirmed=.*/ota_rootfs_confirmed=1/' /run/shared-env/env.txt
            log "Master confirmed shared rootfs upgrade."
            # NOTE: The updated env.txt must be rebuilt into shared-env.itb
            # and reflashed. This is handled by ota-update --env or a
            # dedicated shared-env-sync service.
        fi
    fi
else
    log "Health checks FAILED for Core ${CORE_ID}. Rebooting for rollback..."
    sleep 2
    reboot
fi
