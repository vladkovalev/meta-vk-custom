# =====================================================
# LS1046A OTA Boot Script
# Per-core: reads dedicated env (always) + shared env FIT (if available)
# Computes role via deterministic rotation
# Handles FIT A/B with boot_count rollback
# Selects rootfs A/B from shared env or local fallback
# =====================================================

echo "=== OTA Boot: Core ${core_id} ==="

# ----- Step 1: Load shared env FIT from shared flash -----
setenv shared_env_ok 0

if sf probe ${shared_flash_cs}; then
    if sf read ${loadaddr} ${shared_env_offset} ${shared_env_size}; then
        # Verify FIT integrity
        if iminfo ${loadaddr}; then
            # Extract env data from FIT image
            imxtract ${loadaddr} env ${env_loadaddr}
            env import -t ${env_loadaddr} ${env_data_size}
            setenv shared_env_ok 1

            # Sync local boot cycle from shared
            setenv local_boot_cycle ${boot_cycle}
            setenv shared_env_synced 1
            saveenv
            echo "Shared env FIT loaded: boot_cycle=${boot_cycle}"
        else
            echo "WARNING: Shared env FIT integrity check failed!"
        fi
    else
        echo "WARNING: Failed to read shared env from flash."
    fi
else
    echo "WARNING: Shared flash not accessible."
fi

# Fallback: increment local boot cycle if shared env unavailable
if test "${shared_env_ok}" != "1"; then
    setexpr local_boot_cycle ${local_boot_cycle} + 1
    setenv shared_env_synced 0
    saveenv
    echo "Using local fallback: local_boot_cycle=${local_boot_cycle}"
fi

# ----- Step 2: Compute role -----
# Role = ROLES[ (boot_cycle + core_id - 1) % 3 ]
# ROLES[0]=master, ROLES[1]=slave, ROLES[2]=backup
setexpr role_tmp ${local_boot_cycle} + ${core_id}
setexpr role_tmp ${role_tmp} - 1
setexpr role_index ${role_tmp} % 3

if test ${role_index} -eq 0; then
    setenv core_role master
elif test ${role_index} -eq 1; then
    setenv core_role slave
else
    setenv core_role backup
fi

# Check for manual role override from shared env
if test -n "${master_override}"; then
    if test ${core_id} -eq ${master_override}; then
        setenv core_role master
    fi
fi

echo "Core ${core_id} role: ${core_role}"

# ----- Step 3: Handle FIT A/B (per-core dedicated flash) -----
if test "${fit_upgrade_available}" = "1"; then
    setexpr fit_boot_count ${fit_boot_count} + 1
    saveenv

    if test ${fit_boot_count} -gt ${fit_boot_limit}; then
        echo "FIT boot limit exceeded (${fit_boot_count}/${fit_boot_limit}). Rolling back..."
        if test "${fit_slot}" = "A"; then
            setenv fit_slot B
        else
            setenv fit_slot A
        fi
        setenv fit_boot_count 0
        setenv fit_upgrade_available 0
        saveenv
    fi
fi

if test "${fit_slot}" = "A"; then
    setenv fit_addr ${fit_addr_a}
else
    setenv fit_addr ${fit_addr_b}
fi

# ----- Step 4: Select rootfs slot -----
if test "${shared_env_ok}" = "1"; then
    setenv rootfs_slot ${ota_rootfs_slot}
else
    # Use last known slot from local env
    if test -z "${rootfs_slot}"; then
        setenv rootfs_slot A
    fi
fi

if test "${rootfs_slot}" = "A"; then
    setenv rootfs_label rootfsA
else
    setenv rootfs_label rootfsB
fi

# ----- Step 5: Load FIT from dedicated flash and boot -----
echo "Booting: FIT=${fit_slot}@${fit_addr} RootFS=${rootfs_slot} Role=${core_role}"

sf probe ${dedicated_flash_cs}
sf read ${loadaddr} ${fit_addr} ${fit_size}

setenv bootargs "console=ttyS0,115200 root=LABEL=${rootfs_label} rootfstype=ext4 rootwait rw earlycon=uart8250,mmio,0x21c0500 vk.core_id=${core_id} vk.core_role=${core_role} vk.boot_cycle=${local_boot_cycle} vk.fit_slot=${fit_slot} vk.rootfs_slot=${rootfs_slot}"

bootm ${loadaddr}
