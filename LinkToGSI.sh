#!/bin/bash

ROM_LINK=$1
ROM_TYPE=$2
partitions="
vendor
system
system_ext
product

optics
prism

mi_ext
my_bigball
my_engineering
my_manifest
my_region
my_carrier
my_heytap
my_product
my_stock

tr_carrier
tr_company
tr_manifest
tr_misc
tr_overlayfs
tr_preload
tr_product
tr_region

preas
preavs
preload
product_h
patch_hn
cust
vgc
oem
dyn
"
rm -rf Tools/Firmware_extractor

git clone --depth=1 --recurse-submodules \
    https://github.com/rofikkerneldev/own_extractor.git \
    Tools/Firmware_extractor

usage() {
  echo "Usage: $0 [rom_link] [rom_type]"
  echo ""
  echo "Parameters:"
  echo "  rom_link  - Link to the base ROM"
  echo "  rom_type  - Type of rom"
  echo ""
  echo "Example:"
  echo "  sudo bash $0 https://dl.google.com/dl/android/aosp/redfin-tq3a.230901.001.c2-factory-ca20bd02.zip Pixel"
  echo ""
}

supported_roms() {
    echo "Available ROMs:"
    echo ""
    declare -a versions=(10 11 12 12.1 13 14 15 16 17)
    for version in "${versions[@]}"; do
        rom_dir="ROMsPatches/$version"
        if [ -d "$rom_dir" ]; then
            names=$(find "$rom_dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null)
            filtered=$(echo "$names" | grep -vxF -f <(printf '%s\n' "${versions[@]}"))
            if [ -n "$filtered" ]; then
                echo "Android $version:"
                echo "$filtered" | sed 's|^|  - |' | tr '\n' '\n'
                echo ""
            fi
        fi
    done
}

if [ -z "$2" ]; then
  usage
  supported_roms
  exit 0
fi

rm -rf DownloadedROMs
rm -rf UnpackedROMs

mkdir -p DownloadedROMs
mkdir -p UnpackedROMs

if [ -f "$ROM_LINK" ]; then
    Tools/Firmware_extractor/extractor.sh "$ROM_LINK" "UnpackedROMs/"
else
    wget -P "DownloadedROMs/" "$ROM_LINK"
    Tools/Firmware_extractor/extractor.sh "DownloadedROMs/"* "UnpackedROMs/"
fi
# ============================================================
# VIVO EXTRA IMAGE DECOMPRESSION
# Vivo firmware payload images have an additional ZSTD wrapper.
# Run ONLY when ROM_TYPE is Vivo.
# ============================================================

if [[ "${ROM_TYPE,,}" == "vivo" ]]; then
    echo ""
    echo "============================================"
    echo " VIVO ROM DETECTED"
    echo " Running Vivo image decompressor"
    echo "============================================"

    # Support vivoextractor.py from main repository
    # OR from Tools/Firmware_extractor
    if [[ -f "vivoextractor.py" ]]; then
        VIVO_EXTRACTOR="vivoextractor.py"
    elif [[ -f "Tools/Firmware_extractor/vivoextractor.py" ]]; then
        VIVO_EXTRACTOR="Tools/Firmware_extractor/vivoextractor.py"
    else
        echo "ERROR: vivoextractor.py not found!"
        exit 1
    fi

    echo "Using: $VIVO_EXTRACTOR"

    # Clean previous output if present
    rm -rf "UnpackedROMs/out"

    # Decode Vivo wrapped images
    python3 "$VIVO_EXTRACTOR" "UnpackedROMs"

    if [[ ! -d "UnpackedROMs/out" ]]; then
        echo "ERROR: Vivo extractor did not create UnpackedROMs/out"
        exit 1
    fi

    shopt -s nullglob
    VIVO_IMAGES=(UnpackedROMs/out/*.img)

    if (( ${#VIVO_IMAGES[@]} == 0 )); then
        echo "ERROR: Vivo extractor produced no decoded images!"
        exit 1
    fi

    echo ""
    echo "Replacing wrapped Vivo images with decoded images..."

    for decoded_img in "${VIVO_IMAGES[@]}"; do
        img_name="$(basename "$decoded_img")"

        echo "  -> $img_name"

        mv -f \
            "$decoded_img" \
            "UnpackedROMs/$img_name"
    done

    shopt -u nullglob

    rm -rf "UnpackedROMs/out"

    echo ""
    echo "============================================"
    echo " VIVO IMAGE DECOMPRESSION COMPLETE"
    echo "============================================"

    echo ""
    echo "Filesystem check:"

    for check_img in system system_ext product vendor odm; do
        if [[ -f "UnpackedROMs/$check_img.img" ]]; then
            echo "--------------------------------------------"
            echo "$check_img.img"
            file "UnpackedROMs/$check_img.img" || true
            blkid "UnpackedROMs/$check_img.img" || true
        fi
    done

    echo "============================================"
fi
for partition in $partitions; do
    if [[ -f "UnpackedROMs/$partition.img" ]]; then
        echo "Unpacking file: UnpackedROMs/$partition.img"
        mkdir -p "UnpackedROMs/temp_mount"
        mkdir -p "UnpackedROMs/$partition"
        fs_type=$(blkid -o value -s TYPE "UnpackedROMs/$partition.img" 2>/dev/null)
        if [[ "$fs_type" == "ext2" || "$fs_type" == "ext4" ]]; then
            sudo mount -o loop,ro -t ext4 "UnpackedROMs/$partition.img" "UnpackedROMs/temp_mount"
        else
            sudo mount "UnpackedROMs/$partition.img" "UnpackedROMs/temp_mount"
        fi
       if [ "$partition" = "system" ]; then
    echo "===== ORIGINAL SYSTEM IMAGE SYMLINK CHECK ====="

    sudo ls -ld \
        "UnpackedROMs/temp_mount/etc" \
        "UnpackedROMs/temp_mount/system/product" \
        "UnpackedROMs/temp_mount/system/system_ext" \
        2>/dev/null

    echo "etc -> $(sudo readlink "UnpackedROMs/temp_mount/etc" 2>/dev/null)"
fi
       sudo cp -a "UnpackedROMs/temp_mount/." "UnpackedROMs/$partition/"
sudo chown -R $USER:$USER "UnpackedROMs/$partition"
        sudo umount -R "UnpackedROMs/temp_mount"
    fi
done

for partition in $partitions; do
    if [ "$partition" != "system" ]; then
        if [ -d "UnpackedROMs/system/$partition" ] && [ ! -L "UnpackedROMs/system/$partition" ]; then
            source_dir="UnpackedROMs/system/$partition"
        elif [ -d "UnpackedROMs/system/system/$partition" ] && [ ! -L "UnpackedROMs/system/system/$partition" ]; then
            source_dir="UnpackedROMs/system/system/$partition"
        else
            continue
        fi
        if [ -d "UnpackedROMs/$partition" ]; then
            echo "Moving $partition into root"
            mv "UnpackedROMs/$partition" "$source_dir/.."
        fi
    fi
done

sudo bash FoxetGSITool.sh "UnpackedROMs/system" "$ROM_TYPE"
