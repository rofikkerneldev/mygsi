#!/bin/bash

BASE_DIR=$1
OUTPUT=$2
SCRIPT_DIR=$(dirname "$0")
TEMP_DIR="$SCRIPT_DIR/../../Temp"
SIZE=$(du -sk "$BASE_DIR" | awk '{size=$1; size=size*1024; size=int(size*1.05); printf "%d", size}')

#########################################################
# Collect SELinux file_contexts
#########################################################

rm -f "$TEMP_DIR/file_contexts"
touch "$TEMP_DIR/file_contexts"

SELINUX_DIRS=(
    "$BASE_DIR/system/etc/selinux"
    "$BASE_DIR/system/system/etc/selinux"

    "$BASE_DIR/system_ext/etc/selinux"
    "$BASE_DIR/system/system_ext/etc/selinux"

    "$BASE_DIR/product/etc/selinux"
    "$BASE_DIR/system/product/etc/selinux"
)

SELINUX_FILES=(
    "plat_file_contexts"
    "nonplat_file_contexts"
    "system_ext_file_contexts"
    "product_file_contexts"
)

for dir in "${SELINUX_DIRS[@]}"; do
    [ -d "$dir" ] || continue

    for fc in "${SELINUX_FILES[@]}"; do
        if [ -f "$dir/$fc" ]; then
            echo "Import SELinux: $dir/$fc"
            cat "$dir/$fc" >> "$TEMP_DIR/file_contexts"
            echo >> "$TEMP_DIR/file_contexts"
        fi
    done
done

# Remove duplicated lines but preserve order
awk '!seen[$0]++' "$TEMP_DIR/file_contexts" > "$TEMP_DIR/file_contexts.tmp"
mv "$TEMP_DIR/file_contexts.tmp" "$TEMP_DIR/file_contexts"


#########################################################
# Remove unused Transsion mount points
#########################################################

echo "===== Checking Transsion / SoC mount points ====="

for path in \
    "$BASE_DIR/tranfs" \
    "$BASE_DIR/transfs" \
    "$BASE_DIR/soccp_firmware"
do
    if [[ -e "$path" ]]; then
        echo "FOUND: $path"
    else
        echo "MISSING: $path"
    fi
done

rm -rf "$BASE_DIR/tranfs"
rm -rf "$BASE_DIR/transfs"
rm -rf "$BASE_DIR/soccp_firmware"

echo "===== After cleanup ====="

for path in \
    "$BASE_DIR/tranfs" \
    "$BASE_DIR/transfs" \
    "$BASE_DIR/soccp_firmware"
do
    if [[ -e "$path" ]]; then
        echo "STILL EXISTS: $path"
    else
        echo "REMOVED/MISSING: $path"
    fi
done


#########################################################
# Remove unused Transsion / SoC SELinux contexts
#########################################################

echo "===== SELinux contexts before cleanup ====="

grep -nE '^/(transfs|tranfs|soccp_firmware)(/|[[:space:]])' \
    "$TEMP_DIR/file_contexts" || true

echo "===== Removing unused SELinux contexts ====="

sed -i -E '\#^/(transfs|tranfs|soccp_firmware)(/|[[:space:]])#d' \
    "$TEMP_DIR/file_contexts"

echo "===== SELinux contexts after cleanup ====="

grep -nE '^/(transfs|tranfs|soccp_firmware)(/|[[:space:]])' \
    "$TEMP_DIR/file_contexts" || true


file_contexts="$TEMP_DIR/file_contexts"

append_context() {
    grep -qxF "$1" "$TEMP_DIR/file_contexts" || \
        echo "$1" >> "$TEMP_DIR/file_contexts"
}

if [[ -f "$TEMP_DIR/file_contexts" ]]; then
    append_context "/firmware(/.*)?         u:object_r:firmware_file:s0"
    append_context "/bt_firmware(/.*)?      u:object_r:bt_firmware_file:s0"
    append_context "/persist(/.*)?          u:object_r:mnt_vendor_file:s0"
    append_context "/dsp                    u:object_r:rootfs:s0"
    append_context "/oem                    u:object_r:rootfs:s0"
    append_context "/op1                    u:object_r:rootfs:s0"
    append_context "/op2                    u:object_r:rootfs:s0"
    append_context "/charger_log            u:object_r:rootfs:s0"
    append_context "/audit_filter_table     u:object_r:rootfs:s0"
    append_context "/keydata                u:object_r:rootfs:s0"
    append_context "/keyrefuge              u:object_r:rootfs:s0"
    append_context "/omr                    u:object_r:rootfs:s0"
    append_context "/publiccert.pem         u:object_r:rootfs:s0"
    append_context "/sepolicy_version       u:object_r:rootfs:s0"
    append_context "/cust                   u:object_r:rootfs:s0"
    append_context "/donuts_key             u:object_r:rootfs:s0"
    append_context "/v_key                  u:object_r:rootfs:s0"
    append_context "/carrier                u:object_r:rootfs:s0"
    append_context "/dqmdbg                 u:object_r:rootfs:s0"
    append_context "/ADF                    u:object_r:rootfs:s0"
    append_context "/APD                    u:object_r:rootfs:s0"
    append_context "/asdf                   u:object_r:rootfs:s0"
    append_context "/batinfo                u:object_r:rootfs:s0"
    append_context "/voucher                u:object_r:rootfs:s0"
    append_context "/xrom                   u:object_r:rootfs:s0"
    append_context "/custom                 u:object_r:rootfs:s0"
    append_context "/cpefs                  u:object_r:rootfs:s0"
    append_context "/modem                  u:object_r:rootfs:s0"
    append_context "/module_hashes          u:object_r:rootfs:s0"
    append_context "/pds                    u:object_r:rootfs:s0"
    append_context "/tombstones             u:object_r:rootfs:s0"
    append_context "/factory                u:object_r:rootfs:s0"
    append_context "/oneplus(/.*)?          u:object_r:rootfs:s0"
    append_context "/.recycle(/.*)?         u:object_r:rootfs:s0"
    append_context "/addon.d                u:object_r:rootfs:s0"
    append_context "/op_odm                 u:object_r:rootfs:s0"
    append_context "/avb                    u:object_r:rootfs:s0"
    append_context "/sec_storage            u:object_r:rootfs:s0"
    append_context "/dpolicy                u:object_r:rootfs:s0"
    append_context "/dpolicy_system         u:object_r:rootfs:s0"
    append_context "/optics(/.*)?           u:object_r:rootfs:s0"
    append_context "/prism(/.*)?            u:object_r:rootfs:s0"
    append_context "/spu                    u:object_r:rootfs:s0"
    append_context "/mi_ext(/.*)?           u:object_r:rootfs:s0"
    append_context "/opconfig               u:object_r:rootfs:s0"
    append_context "/opcust                 u:object_r:rootfs:s0"
    append_context "/my_bigball(/.*)?       u:object_r:rootfs:s0"
    append_context "/my_carrier(/.*)?       u:object_r:rootfs:s0"
    append_context "/my_company(/.*)?       u:object_r:rootfs:s0"
    append_context "/my_engineering(/.*)?   u:object_r:rootfs:s0"
    append_context "/my_heytap(/.*)?        u:object_r:rootfs:s0"
    append_context "/my_manifest(/.*)?      u:object_r:rootfs:s0"
    append_context "/my_preload(/.*)?       u:object_r:rootfs:s0"
    append_context "/my_product(/.*)?       u:object_r:rootfs:s0"
    append_context "/my_region(/.*)?        u:object_r:rootfs:s0"
    append_context "/my_reserve(/.*)?       u:object_r:rootfs:s0"
    append_context "/my_stock(/.*)?         u:object_r:rootfs:s0"
    append_context "/special_preload        u:object_r:rootfs:s0"
    append_context "/blackbox               u:object_r:rootfs:s0"

    file_contexts="$TEMP_DIR/file_contexts"
fi

 rm -rf "$BASE_DIR/persist"
 rm -rf "$BASE_DIR/bt_firmware"
 rm -rf "$BASE_DIR/firmware"
 rm -rf "$BASE_DIR/dsp"
rm -rf "$BASE_DIR/cache"
 mkdir -p "$BASE_DIR/bt_firmware"
 mkdir -p "$BASE_DIR/persist"
 mkdir -p "$BASE_DIR/firmware"
 mkdir -p "$BASE_DIR/dsp"
 mkdir -p "$BASE_DIR/cache"

echo "Output image size: $(echo "scale=2; $SIZE / (1024^3)" | bc) GB"
$SCRIPT_DIR/mkuserimg_mke2fs.sh "$BASE_DIR/" "$OUTPUT" ext4 "/" $SIZE $file_contexts -j "0" -T "1230768000" -L "/" -I "256" -M "/" -m "5"
