#!/bin/bash

ROM_LINK=$1
TARGET_PARTITION=$2

# =========================
# PRIVILEGE HELPER (ADD THIS)
# =========================
#if [[ "$EUID" -ne 0 ]]; then
 #   exec sudo bash "$0" "$@"
#fi

rm -rf Tools/Firmware_extractor

git clone --depth=1 --recurse-submodules \
    https://github.com/rofikkerneldev/own_extractor.git \
    Tools/Firmware_extractor
    
#partitions="vendor system system_ext product optics prism mi_ext my_bigball my_engineering my_manifest my_region my_carrier my_heytap my_product my_stock"
partitions="$TARGET_PARTITION"

# Clean unpack only
rm -rf UnpackedROMs
mkdir -p UnpackedROMs

# Handle ROM source
if [ -f "$ROM_LINK" ]; then

    echo "Using local ROM file:"
    echo "$ROM_LINK"

    ROM_FILE="$ROM_LINK"

else

    echo "Downloading ROM..."

    
    mkdir -p DownloadedROMs
    #rm -rf DownloadedROMs
    mv DownloadedROMs/rom.zip DownloadedROMs/rom_backup.zip
    wget -O "DownloadedROMs/rom.zip" "$ROM_LINK"

    ROM_FILE="DownloadedROMs/rom.zip"

fi
# Extract firmware
Tools/Firmware_extractor/extractor.sh "$ROM_FILE" "UnpackedROMs/"

IMG_FILE="UnpackedROMs/${TARGET_PARTITION}.img"
ZIP_FILE="${TARGET_PARTITION}.zip"

if [[ ! -f "$IMG_FILE" ]]; then
    echo "ERROR: ${TARGET_PARTITION}.img not found!"
    echo
    echo "Available images:"
    ls -1 UnpackedROMs/*.img 2>/dev/null
    exit 1
fi

echo "Creating $ZIP_FILE..."

rm -f "$ZIP_FILE"

zip -j -9 "$ZIP_FILE" "$IMG_FILE"

echo
echo "Done!"
echo "Created: $ZIP_FILE"

unzip -l "$ZIP_FILE"






