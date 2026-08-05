#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
BASE_DIR="$1"

if [ -d "$BASE_DIR/product" ] && [ ! -L "$BASE_DIR/product" ]; then
    product="$BASE_DIR/product"
elif [ -d "$BASE_DIR/system/product" ] && [ ! -L "$BASE_DIR/system/product" ]; then
    product="$BASE_DIR/system/product"
else
    echo "error: No product dir"
    exit 1
fi

if [ -d "$BASE_DIR/system_ext" ] && [ ! -L "$BASE_DIR/system_ext" ]; then
    system_ext="$BASE_DIR/system_ext"
elif [ -d "$BASE_DIR/system/system_ext" ] && [ ! -L "$BASE_DIR/system/system_ext" ]; then
    system_ext="$BASE_DIR/system/system_ext"
else
    echo "error: No system_ext dir"
    exit 1
fi

echo "Applying HiOS patches..."

# clearSELinux Transsion
find "$BASE_DIR" -type f \( -name "*file_contexts*" -o -name "*.cil" -o -name "*property_contexts*" \) \
    -exec sed -i '/tr_/d;/transsion/d;/tecno/d;/infinix/d;/itel/d' {} +

# clean seapp_contexts bila ada
[ -f "$product/etc/selinux/product_seapp_contexts" ] && \
    sed -i '/tr_/d;/transsion/d' "$product/etc/selinux/product_seapp_contexts"

[ -f "$system_ext/etc/selinux/system_ext_seapp_contexts" ] && \
    sed -i '/tr_/d;/transsion/d' "$system_ext/etc/selinux/system_ext_seapp_contexts"
