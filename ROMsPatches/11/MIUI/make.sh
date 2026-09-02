#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
BASE_DIR=$1

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

rm -rf $BASE_DIR/system/app/AiAsstVision
rm -rf $BASE_DIR/system/app/AnalyticsCore
rm -rf $BASE_DIR/system/app/MIUIFrequentPhrase
rm -rf $BASE_DIR/system/app/MIpay
rm -rf $BASE_DIR/system/app/MSA
rm -rf $BASE_DIR/system/app/MiConnectService*
rm -rf $BASE_DIR/system/app/MiGameService
rm -rf $BASE_DIR/system/app/MiLink
rm -rf $BASE_DIR/system/app/MiuiDaemon
rm -rf $BASE_DIR/system/app/MiuiSuperMarket
rm -rf $BASE_DIR/system/app/NextPay
rm -rf $BASE_DIR/system/app/TSMClient
rm -rf $BASE_DIR/system/app/UPTsmService
rm -rf $BASE_DIR/system/app/Updater
rm -rf $BASE_DIR/system/app/VoiceAssist
rm -rf $BASE_DIR/system/app/VoiceTrigger
rm -rf $BASE_DIR/system/app/MIUIWallper*
rm -rf $BASE_DIR/system/app/MiuiBugReport
rm -rf $BASE_DIR/system/app/PaymentService
rm -rf $BASE_DIR/system/app/MIUIContentExtension
rm -rf $BASE_DIR/system/data-app/MIUIWallper*
rm -rf $BASE_DIR/system/data-app/Email
rm -rf $BASE_DIR/system/data-app/Health
rm -rf $BASE_DIR/system/data-app/MIFinance
rm -rf $BASE_DIR/system/data-app/MIGalleryLockscreen
rm -rf $BASE_DIR/system/data-app/MIMediaEditor*
rm -rf $BASE_DIR/system/data-app/MIUIDuokanReader
rm -rf $BASE_DIR/system/data-app/MIUIGameCenter
rm -rf $BASE_DIR/system/data-app/MIUIHuanji
rm -rf $BASE_DIR/system/data-app/MIUINewHome
rm -rf $BASE_DIR/system/data-app/MIUIVipAccount
rm -rf $BASE_DIR/system/data-app/MIUIVirtualSim
rm -rf $BASE_DIR/system/data-app/MIUIXiaoAiSpeechEngine
rm -rf $BASE_DIR/system/data-app/MIUIYoupin
rm -rf $BASE_DIR/system/data-app/MiDrive
rm -rf $BASE_DIR/system/data-app/MiShop
rm -rf $BASE_DIR/system/data-app/MIShop
rm -rf $BASE_DIR/system/data-app/MiuiScanner
rm -rf $BASE_DIR/system/data-app/SmartHome
rm -rf $BASE_DIR/system/data-app/XMRemoteController
rm -rf $BASE_DIR/system/data-app/wps-lite
rm -rf $BASE_DIR/system/data-app/MIRadio
rm -rf $BASE_DIR/system/data-app/MIUIEmail
rm -rf $BASE_DIR/system/data-app/MIUIMusic*
rm -rf $BASE_DIR/system/data-app/MIUIVideo*
rm -rf $BASE_DIR/system/data-app/MIpay
rm -rf $BASE_DIR/system/data-app/MiuiHealth
rm -rf $product/data-app/BaiduIME
rm -rf $product/data-app/com.iflytek.inputmethod.miui
rm -rf $BASE_DIR/system/priv-app/FindDevice
rm -rf $BASE_DIR/system/priv-app/MIService
rm -rf $BASE_DIR/system/priv-app/MIShare
rm -rf $BASE_DIR/system/priv-app/MIUIMirror
rm -rf $BASE_DIR/system/priv-app/MIUIPersonalAssistant
rm -rf $BASE_DIR/system/priv-app/MIUIQuickSearchBox
rm -rf $BASE_DIR/system/priv-app/MIUIVideo
rm -rf $BASE_DIR/system/priv-app/MIUIMusic
rm -rf $BASE_DIR/system/priv-app/MIUIVipService
rm -rf $BASE_DIR/system/priv-app/MIUIYellowPage
rm -rf $BASE_DIR/system/priv-app/MiBrowser
rm -rf $BASE_DIR/system/priv-app/MiGameCenterSDKService
rm -rf $BASE_DIR/system/priv-app/MiuiExtraPhoto
rm -rf $BASE_DIR/system/priv-app/MiExtraPhoto
rm -rf $product/app/mi_aiasst_service

# Switch to AOSP SetupWizard
rm -rf $BASE_DIR/system/priv-app/Provision
rsync -ra $SCRIPT_DIR/SetupWizard $BASE_DIR/system/priv-app/

# Remove init.recovery.hardware
rm -rf $BASE_DIR/init.recovery.hardware.rc

# Switch to OpenCamera
rm -rf $BASE_DIR/system/priv-app/MiuiCamera
rsync -ra $SCRIPT_DIR/OpenCamera $BASE_DIR/system/priv-app/

# Switch to AOSP init
rsync -ra $SCRIPT_DIR/bin/ $BASE_DIR/system/bin/

# Lag fix
echo "ro.surface_flinger.use_content_detection_for_refresh_rate=true" >> $BASE_DIR/system/build.prop
echo "ro.surface_flinger.set_idle_timer_ms=2147483647" >> $BASE_DIR/system/build.prop
echo "ro.surface_flinger.set_touch_timer_ms=2147483647" >> $BASE_DIR/system/build.prop
echo "ro.surface_flinger.set_display_power_timer_ms=2147483647" >> $BASE_DIR/system/build.prop

# Remove mi_ext partition
if [ -d "$BASE_DIR/mi_ext/" ]; then
    if [ -f "$BASE_DIR/mi_ext/etc/build.prop" ]; then
        cat "$BASE_DIR/mi_ext/etc/build.prop" >> "$BASE_DIR/system/build.prop"
    fi
    if [ -d "$BASE_DIR/mi_ext/product/" ]; then
        rsync -ra "$BASE_DIR/mi_ext/product/" "$product/"
    fi
    if [ -d "$BASE_DIR/mi_ext/system_ext/" ]; then
        rsync -ra "$BASE_DIR/mi_ext/system_ext/" "$system_ext/"
    fi
    if [ -d "$BASE_DIR/mi_ext/system/" ]; then
        rsync -ra "$BASE_DIR/mi_ext/system/" "$BASE_DIR/system/"
    fi
    rm -rf "$BASE_DIR/mi_ext/"
fi
