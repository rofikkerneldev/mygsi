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

sed -i "/dataservice_app/d" $product/etc/selinux/product_seapp_contexts
sed -i "/dataservice_app/d" $system_ext/etc/selinux/system_ext_seapp_contexts

# Delete Google apps
rm -rf $BASE_DIR/system/app/datastatusnotification
rm -rf $BASE_DIR/system/app/QAS_DVC_MSP_VZW
rm -rf $BASE_DIR/system/app/VZWAPNLib
rm -rf $BASE_DIR/system/app/vzw_msdc_api
rm -rf $BASE_DIR/system/priv-app/CNEService
rm -rf $BASE_DIR/system/priv-app/DMService
rm -rf $BASE_DIR/system/priv-app/VzwOmaTrigger
rm -rf $BASE_DIR/system/etc/permissions/com.google.android.camera.experimental2017.xml
rm -rf $product/app/YouTubeMusicPrebuilt
rm -rf $product/app/PrebuiltGmail
rm -rf $product/app/Maps
rm -rf $product/app/Drive
rm -rf $product/app/DiagnosticsToolPrebuilt
rm -rf $product/app/CalendarGooglePrebuilt
rm -rf $product/app/NgaResources
rm -rf $product/app/DevicePolicyPrebuilt

# Hotword
rm -rf $product/priv-app/HotwordEnrollment*
rm -rf $system_ext/framework/com.android.hotwordenrollment*
rm -rf $system_ext/framework/oat/arm/com.android.hotwordenrollment*
rm -rf $system_ext/framework/oat/arm64/com.android.hotwordenrollment*
