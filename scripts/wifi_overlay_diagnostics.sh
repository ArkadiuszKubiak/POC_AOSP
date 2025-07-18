#!/bin/bash

# WiFi Overlay Diagnostics Script
# This script helps diagnose WiFi overlay issues

echo "=== WiFi Overlay Diagnostics ==="
echo

# Check if device is connected
echo "Checking ADB connection..."
adb devices
echo

# Step 1: Check overlay status
echo "=== Step 1: Checking overlay status ==="
echo "All overlays:"
adb shell cmd overlay list | grep -i wifi
echo

echo "WifiOverlay specific:"
adb shell cmd overlay list | grep -i wifion
echo

# Step 2: Check overlay target
echo "=== Step 2: Checking overlay target ==="
adb shell pm dump com.droidlogic.wifion | grep -A 5 -B 5 "targetPackage\|overlay"
echo

# Step 3: Check WiFi settings
echo "=== Step 3: Checking WiFi settings ==="
echo "Current WiFi state:"
adb shell settings get global wifi_on
echo

echo "Default WiFi setting:"
adb shell settings get global def_wifi_on
echo

# Step 4: Check if overlay files exist
echo "=== Step 4: Checking overlay files ==="
echo "Product overlay directory:"
adb shell find /product/overlay -name "*wifi*" -o -name "*Wifi*" 2>/dev/null
echo

echo "Vendor overlay directory:"
adb shell find /vendor/overlay -name "*wifi*" -o -name "*Wifi*" 2>/dev/null || echo "No vendor overlay found"
echo

# Step 5: Check overlay content
echo "=== Step 5: Checking overlay APK content ==="
echo "Extracting overlay resources..."
adb shell "cd /product/overlay && ls -la *[Ww]ifi*"
echo

# Step 6: Check SettingsProvider
echo "=== Step 6: Checking SettingsProvider ==="
adb shell pm dump com.android.providers.settings | grep -i "wifi\|overlay" | head -10
echo

# Step 7: Check system properties
echo "=== Step 7: Checking system properties ==="
adb shell getprop | grep -i wifi | head -5
echo

echo "=== Diagnosis Complete ==="
echo "Please check the output above for any issues."
