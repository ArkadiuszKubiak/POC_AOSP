# Android Resource Management & Runtime Resource Overlays (RROs)

This document provides comprehensive information about Android Resource Management system and Runtime Resource Overlays (RROs) in AOSP, focusing on practical implementation and debugging techniques.

## Author Information

**Created by:** Arkadiusz Kubiak  
**Purpose:** Android Resource Management and RRO Documentation  
**Architecture Focus:** Resource Overlay Systems and Android Resource Framework  
**LinkedIn:** [www.linkedin.com/in/arkadiusz-kubiak-1b4994150](https://www.linkedin.com/in/arkadiusz-kubiak-1b4994150)

---

## Table of Contents
1. [What is Android Resource Management?](#what-is-android-resource-management)
2. [Runtime Resource Overlays (RROs)](#runtime-resource-overlays-rros)
3. [RRO Priority System](#rro-priority-system)
4. [Case Study: def_wifi_on Resource in sdk_car_x86_64](#case-study-def_wifi_on-resource-in-sdk_car_x86_64)
   - [Resource Usage in SettingsProvider](#resource-usage-in-settingsprovider)
   - [Multiple Overlay Sources](#multiple-overlay-sources-for-def_wifi_on)
   - [Why Multiple Partitions?](#why-multiple-partitions-for-same-overlay)
   - [Overlay Inheritance Chain (sdk_car_x86_64)](#overlay-inheritance-chain-sdk_car_x86_64)
5. [Debugging Overlay Issues](#debugging-overlay-issues)
6. [Forcing Overlay Rebuilds](#forcing-overlay-rebuilds)
7. [Best Practices](#best-practices)
8. [Common Issues and Solutions](#common-issues-and-solutions)
8. [Forcing Overlay Rebuilds](#forcing-overlay-rebuilds)

---

## What is Android Resource Management?

Android Resource Management is a system that allows applications to access resources (strings, booleans, integers, drawables, etc.) through resource identifiers. The Android resource system supports multiple configurations and provides a mechanism for customizing resources without modifying the application code.

### Key Features:
- **Resource Identification**: Uses unique resource IDs for accessing resources
- **Configuration Support**: Handles different screen densities, orientations, locales
- **Runtime Resolution**: Resolves appropriate resource based on current configuration
- **Overlay Support**: Allows runtime modification of resources through overlays

## Runtime Resource Overlays (RROs)

Runtime Resource Overlays are APK files that can override resources in target applications at runtime. They are packaged separately from the target application and can be enabled/disabled dynamically without rebuilding the target app.

### How RROs Work:
1. **Build Time**: Overlay APKs are generated from overlay sources
2. **Install Time**: Overlays are installed to specific partitions
3. **Runtime**: Resource Manager applies overlays based on priority
4. **Dynamic Control**: Overlays can be enabled/disabled without reboot

### RRO Benefits:
- **Customization**: OEMs can customize Android without modifying AOSP
- **Modularity**: Changes are isolated in separate APK files
- **Maintainability**: Updates don't require full system rebuilds
- **Flexibility**: Multiple overlays can target the same resources

## RRO Priority System

Android uses a hierarchical priority system for overlays across different partitions. When multiple overlays override the same resources, the order of the overlays is important. An overlay has greater precedence than overlays with configurations preceding its own configuration.

### Priority Hierarchy (from least to greatest precedence):
1. **System** (`/system/overlay/`) - **LOWEST PRIORITY**
2. **Vendor** (`/vendor/overlay/`)
3. **ODM** (`/odm/overlay/`)
4. **OEM** (`/oem/overlay/`)
5. **Product** (`/product/overlay/`)
6. **System Extension** (`/system_ext/overlay/`) - **HIGHEST PRIORITY**

### How Priority Works:
- When multiple overlays define the same resource, the overlay with the highest priority takes precedence
- If system_ext overlay doesn't define a resource, system checks product overlay
- The system continues down the hierarchy until it finds a defined resource or uses the original value
- If no overlay defines the resource, system uses original resource value

### Example Priority Resolution:
```
Resource: def_wifi_on
├── System Extension: <not defined>
├── Product Overlay: false      ← USED (highest priority with value)
├── OEM Overlay: <not defined>
├── ODM Overlay: <not defined>
├── Vendor Overlay: true        ← IGNORED (lower priority)
└── System Overlay: true        ← IGNORED (lower priority)

Result: def_wifi_on = false
```

### How Overlay Priorities Are Determined

The overlay priority values are determined by Android's overlay management system and are influenced by several factors:

#### 1. Partition-Based Priority Base Values
- **System partition** (`/system/overlay/`): Base priority ~1-5
- **Vendor partition** (`/vendor/overlay/`): Base priority ~6-10  
- **Product partition** (`/product/overlay/`): Base priority ~15-20
- **System Extension partition** (`/system_ext/overlay/`): Base priority ~25-30

#### 2. Installation Order and Configuration
- Overlays installed later may receive higher priorities within the same partition
- Build system can assign specific priorities through configuration
- Static overlays (defined in `AndroidManifest.xml`) may have different priority calculation

#### 3. Real Priority Values (emulator_car64_x86_64)
Based on actual ADB dump data, the priority assignment for SettingsProvider overlays is:

```bash
# Command to verify priorities:
adb shell cmd overlay dump | grep -A 10 "com.android.providers.settings"

# Results:
com.android.providers.settings.auto_generated_rro_product__  → Priority: 19
com.android.providers.settings.car.config.rro               → Priority: 18  
com.android.providers.settings.auto_generated_rro_vendor__  → Priority: 6
```

**Key Insight**: Higher priority number = higher precedence. Priority 19 overrides priority 18, which overrides priority 6.

#### 4. Why Car Common Overlay Has Higher Priority Than Car Config RRO
The car common overlay (`auto_generated_rro_product`) gets priority 19 while Car Config RRO gets priority 18 because:

1. **Auto-generated overlays** from `PRODUCT_PACKAGE_OVERLAYS` may receive higher priority
2. **Installation timing** during build process affects priority assignment
3. **Product partition** overlays are processed after static RRO definitions
4. **Build system logic** assigns incremental priorities within the same partition

This explains why device-specific customizations can override platform defaults - the build system ensures that more specific (device-level) overlays take precedence over general (platform-level) configurations.

## Case Study: def_wifi_on Resource in sdk_car_x86_64

Let's examine how the `def_wifi_on` boolean resource is managed through overlays specifically in the AOSP `sdk_car_x86_64` target.

### Source Files and Locations (sdk_car_x86_64 Target Only)

The `def_wifi_on` resource is defined in locations specifically used by the `sdk_car_x86_64` target:

#### Original Resource Definition
- **Path**: [`frameworks/base/packages/SettingsProvider/res/values/defaults.xml`](frameworks/base/packages/SettingsProvider/res/values/defaults.xml)
- **Value**: `<bool name="def_wifi_on">false</bool>` (base AOSP default)

#### Overlay Definitions Used by sdk_car_x86_64 (Based on Real Emulator Data)

##### 1. Car Common Overlay (Product Partition - HIGHEST PRIORITY)
- **Path**: [`device/generic/car/common/overlay/frameworks/base/packages/SettingsProvider/res/values/defaults.xml`](device/generic/car/common/overlay/frameworks/base/packages/SettingsProvider/res/values/defaults.xml)
- **Value**: `<bool name="def_wifi_on">false</bool>`
- **Generated APK**: `/product/overlay/SettingsProvider__sdk_car_x86_64__auto_generated_rro_product.apk`
- **Overlay Name**: `com.android.providers.settings.auto_generated_rro_product__`
- **Priority**: `19` (HIGHEST - controls final value)
- **Configured in**: `sdk_car_x86_64.mk` via `PRODUCT_PACKAGE_OVERLAYS`
- **Purpose**: Device-specific car customizations

##### 2. Car Settings Provider Config RRO (Product Partition - MEDIUM PRIORITY)
- **Path**: [`packages/services/Car/car_product/rro/overlay-config/SettingsProviderRRO/res/values/defaults.xml`](packages/services/Car/car_product/rro/overlay-config/SettingsProviderRRO/res/values/defaults.xml)
- **Value**: `<bool name="def_wifi_on">false</bool>`
- **Generated APK**: `/product/overlay/CarSettingsProviderConfigRRO.apk`
- **Overlay Name**: `com.android.providers.settings.car.config.rro`
- **Priority**: `18` (overridden by car common overlay)
- **Purpose**: Official Car platform configuration defaults

##### 3. Goldfish Emulator Overlay (Vendor Partition - LOWEST PRIORITY)
- **Path**: [`device/generic/goldfish/overlay/frameworks/base/packages/SettingsProvider/res/values/defaults.xml`](device/generic/goldfish/overlay/frameworks/base/packages/SettingsProvider/res/values/defaults.xml)
- **Value**: `<bool name="def_wifi_on">true</bool>`
- **Generated APK**: `/vendor/overlay/SettingsProvider__sdk_car_x86_64__auto_generated_rro_vendor.apk`
- **Overlay Name**: `com.android.providers.settings.auto_generated_rro_vendor__`
- **Priority**: `6` (ignored - lowest priority)
- **Configured in**: `car_emulator_vendor.mk` via `DEVICE_PACKAGE_OVERLAYS`
- **Purpose**: Emulator-specific defaults

### Resource Usage in SettingsProvider

The `def_wifi_on` resource is used in the SettingsProvider to initialize the default WiFi state when the system database is first created:

**Source**: [`frameworks/base/packages/SettingsProvider/src/com/android/providers/settings/DatabaseHelper.java:2447`](frameworks/base/packages/SettingsProvider/src/com/android/providers/settings/DatabaseHelper.java#L2447)

```java
// Initialize WiFi default state from overlay resource
loadBooleanSetting(stmt, Settings.Global.WIFI_ON, R.bool.def_wifi_on);
```

The `loadBooleanSetting` method retrieves the boolean value from the overlay system:

```java
private void loadBooleanSetting(SQLiteStatement stmt, String key, int resid) {
    loadSetting(stmt, key,
            mContext.getResources().getBoolean(resid) ? "1" : "0");
}
```

### Resource Resolution Flow:
1. **DatabaseHelper** calls `loadBooleanSetting()` with `R.bool.def_wifi_on`
2. **Resource Manager** resolves resource ID through overlay system
3. **Overlay Manager** checks overlays in priority order (system_ext → product → oem → odm → vendor → system)
4. **Final Value** is returned to SettingsProvider for database initialization

### Multiple Overlay Sources for `def_wifi_on`

In `sdk_car_x86_64` target configuration, `def_wifi_on` is actually defined in **THREE** active overlay sources:

#### 1. Car Common Overlay (Product Partition - HIGHEST PRIORITY)
- **Path**: `device/generic/car/common/overlay/frameworks/base/packages/SettingsProvider/res/values/defaults.xml`
- **Generated APK**: `/product/overlay/SettingsProvider__sdk_car_x86_64__auto_generated_rro_product.apk`
- **Overlay Name**: `com.android.providers.settings.auto_generated_rro_product__`
- **Priority**: `19` (HIGHEST - controls final value)
- **Purpose**: Device-specific car customizations

#### 2. Car Settings Provider Config RRO (Product Partition - MEDIUM PRIORITY)
- **Path**: `packages/services/Car/car_product/rro/overlay-config/SettingsProviderRRO/res/values/defaults.xml`
- **Generated APK**: `/product/overlay/CarSettingsProviderConfigRRO.apk`
- **Overlay Name**: `com.android.providers.settings.car.config.rro`
- **Priority**: `18` (overridden by car common overlay)
- **Purpose**: Official Car platform configuration defaults

#### 3. Goldfish Emulator Overlay (Vendor Partition - LOWEST PRIORITY)
- **Path**: `device/generic/goldfish/overlay/frameworks/base/packages/SettingsProvider/res/values/defaults.xml`
- **Generated APK**: `/vendor/overlay/SettingsProvider__sdk_car_x86_64__auto_generated_rro_vendor.apk`
- **Overlay Name**: `com.android.providers.settings.auto_generated_rro_vendor__`
- **Priority**: `6` (ignored - lowest priority)
- **Purpose**: Emulator-specific defaults

### Why Multiple Partitions for Same Overlay?

The Android build system automatically generates overlay APKs for different partitions from a single overlay source. This happens for several reasons:

#### 1. Partition Compatibility
- Different Android versions may prioritize different partitions
- Ensures compatibility across various Android configurations
- Provides consistent behavior regardless of partition availability

#### 2. Vendor/Product Separation
- Allows different levels of customization across the partition hierarchy
- Maintains clear separation between vendor, product, and system customizations
- Enables granular control over resource priorities according to the established hierarchy
- Product partition overlays have higher priority than vendor partition overlays

#### 3. Treble Compliance
- Maintains separation between vendor and system components
- Ensures Project Treble requirements are met
- Allows independent updates of vendor and system partitions

#### 4. Fallback Mechanism
- If one partition is missing or corrupted, system can fall back to another
- Provides redundancy for critical system resources
- Improves system reliability and recovery capabilities

### Example from sdk_car_x86_64 Configuration:
The build system automatically generates overlay APKs from the following sources:
- **Car Common Source**: `device/generic/car/common/overlay`
  - **Generated Product Overlay**: `/product/overlay/SettingsProvider__sdk_car_x86_64__auto_generated_rro_product.apk`
- **Goldfish Source**: `device/generic/goldfish/overlay`  
  - **Generated Vendor Overlay**: `/vendor/overlay/SettingsProvider__sdk_car_x86_64__auto_generated_rro_vendor.apk`

### Overlay Inheritance Chain (sdk_car_x86_64)

The `sdk_car_x86_64` target inherits overlays from multiple sources through a complex inheritance chain:

```makefile
# sdk_car_x86_64.mk configuration:
PRODUCT_PACKAGE_OVERLAYS := device/generic/car/common/overlay

# Inheritance chain:
# 1. sdk_car_x86_64.mk
# 2. → car_emulator_product.mk
# 3. → → car_product.mk (adds CarSettingsProviderConfigRRO)
# 4. → car_emulator_vendor.mk
# 5. → → DEVICE_PACKAGE_OVERLAYS := device/generic/goldfish/overlay
```

This creates **THREE** distinct overlay sources for SettingsProvider:

```
sdk_car_x86_64 Complete Overlay Hierarchy:
├── Product Partition (HIGH PRIORITY)
│   ├── SettingsProvider__sdk_car_x86_64__auto_generated_rro_product.apk (Priority 19 - HIGHEST) ✓ APPLIED
│   │   └── Source: device/generic/car/common/overlay (from sdk_car_x86_64.mk)
│   │   └── def_wifi_on = false (CONTROLS FINAL VALUE)
│   │
│   └── CarSettingsProviderConfigRRO.apk (Priority 18 - MEDIUM)
│       └── Source: packages/services/Car/car_product/build/car_product.mk
│       └── def_wifi_on = false (IGNORED - lower priority than car common)
│
└── Vendor Partition (LOWEST PRIORITY)
    └── SettingsProvider__sdk_car_x86_64__auto_generated_rro_vendor.apk (Priority 6)
        └── Source: device/generic/goldfish/overlay (from car_emulator_vendor.mk)
        └── def_wifi_on = true (IGNORED - lowest priority)
```

**Key Discovery**: Real emulator data shows that the **car common overlay** (priority 19) actually has higher priority than the **Car Config RRO** (priority 18), making the car common overlay the controlling overlay for `def_wifi_on`.

**Critical Finding**: The Android build system assigns higher priorities to device-specific overlays (auto-generated from `PRODUCT_PACKAGE_OVERLAYS`) than to platform-level static RROs, ensuring that device customizations take precedence over general platform defaults.

**Result**: The `device/generic/car/common/overlay` definition of `def_wifi_on=false` is the final controlling value, not the Car Config RRO as initially assumed.

## Debugging Overlay Issues

When working with overlays, use these ADB commands to debug overlay behavior:

### Real-World Example: Debugging `def_wifi_on` on `sdk_car_x86_64`

Based on actual emulator analysis, here are the commands and their outputs:

#### 1. List Active SettingsProvider Overlays
```bash
adb shell cmd overlay list | grep -i settings
```

**Output (sdk_car_x86_64 specific):**
```
com.android.providers.settings
[x] com.android.providers.settings.auto_generated_rro_vendor__
[x] com.android.providers.settings.car.config.rro
[x] com.android.providers.settings.auto_generated_rro_product__
```

**Analysis:** Three overlays are active (`[x]`) for SettingsProvider in `sdk_car_x86_64`:
- `com.android.providers.settings.auto_generated_rro_vendor__` (priority 6 - goldfish overlay - vendor partition)
- `com.android.providers.settings.car.config.rro` (priority 18 - Car Config RRO - product partition)
- `com.android.providers.settings.auto_generated_rro_product__` (priority 19 - car common overlay - product partition - HIGHEST)

#### 2. Find `def_wifi_on` Resource Mappings
```bash
adb shell cmd overlay dump | grep -A 5 -B 5 def_wifi_on
```

**Key Findings:**
- **Product Overlay (Priority 19)**: `0x7f020043 -> 0x7f010001 (bool/def_wifi_on -> bool/def_wifi_on)` - car common overlay (HIGHEST)
- **Car Config RRO (Priority 18)**: `0x7f020043 -> 0x7f010003 (bool/def_wifi_on -> bool/def_wifi_on)` - official car config (MEDIUM)
- **Vendor Overlay (Priority 6)**: `0x7f020043 -> 0x7f010002 (bool/def_wifi_on -> bool/def_wifi_on)` - goldfish overlay (LOWEST)

#### 3. Check Current WiFi State
```bash
adb shell settings get global wifi_on
```

**Output:** `0` (WiFi is disabled by default - Car Common overlay with priority 19 controls the final value)

#### 4. Verify Overlay File Locations
```bash
# Vendor partition
adb shell ls -la /vendor/overlay/ | grep Settings

# Product partition  
adb shell ls -la /product/overlay/ | grep Settings
```

**Vendor Overlay (sdk_car_x86_64):**
```
-rw-r--r--  1 root root   8542 2025-07-15 23:54 SettingsProvider__sdk_car_x86_64__auto_generated_rro_vendor.apk (Priority 6 - LOWEST)
```

**Product Overlays (sdk_car_x86_64) - Priority Order:**
```
-rw-r--r--  1 root root   8542 2025-07-19 14:13 SettingsProvider__sdk_car_x86_64__auto_generated_rro_product.apk (Priority 19 - HIGHEST)
-rw-r--r--  1 root root   8542 2025-07-15 00:01 CarSettingsProviderConfigRRO.apk (Priority 18 - MEDIUM)
```

### Priority Resolution Analysis (sdk_car_x86_64)

Based on the partition hierarchy and actual priority values from the running emulator, the effective priority for overlays in `sdk_car_x86_64` target is:

1. **SettingsProvider__sdk_car_x86_64__auto_generated_rro_product.apk** (product partition, priority 19) - **HIGHEST**
   - Source: `device/generic/car/common/overlay`
   - Car device-specific customizations - **THIS OVERLAY CONTROLS def_wifi_on!**
   
2. **CarSettingsProviderConfigRRO.apk** (product partition, priority 18) - **MEDIUM**
   - Source: `packages/services/Car/car_product/rro/overlay-config/`
   - Official Car platform configuration (overridden by higher priority)
   
3. **SettingsProvider__sdk_car_x86_64__auto_generated_rro_vendor.apk** (vendor partition, priority 6) - **LOWEST**
   - Source: `device/generic/goldfish/overlay`  
   - Emulator-specific defaults (ignored)

**Result**: The Car Common overlay (auto_generated_rro_product) with priority 19 takes highest precedence and controls the final `def_wifi_on` value. The ADB command `adb shell settings get global wifi_on` returns the value from the highest priority overlay.

### Basic Overlay Commands:
```bash
# List all active overlays for SettingsProvider
adb shell cmd overlay list | grep settings

# Check current WiFi default value
adb shell settings get global wifi_on

# Dump overlay mappings
adb shell cmd overlay dump | grep def_wifi_on
```

### Advanced Debugging (sdk_car_x86_64):
```bash
# Check overlay files for sdk_car_x86_64
adb shell ls -la /vendor/overlay/ | grep sdk_car_x86_64
adb shell ls -la /product/overlay/ | grep sdk_car_x86_64

# Examine specific sdk_car_x86_64 overlays
adb shell cmd overlay dump com.android.providers.settings.auto_generated_rro_vendor__
adb shell cmd overlay dump com.android.providers.settings.auto_generated_rro_product__

# Check car-specific overlay configuration
adb shell cmd overlay list | grep car
```

### Log Analysis:
```bash
# Check overlay manager logs
adb logcat -d | grep OverlayManager

# Check service manager logs for overlay registration
adb logcat -d | grep servicemanager

# Check resource resolution logs
adb logcat -d | grep Resources
```

## Best Practices

### 1. Overlay Design
- **Use meaningful names**: Choose descriptive overlay package names
- **Keep overlays focused**: Each overlay should have a single, clear purpose
- **Document thoroughly**: Include comprehensive documentation for overlay resources
- **Plan for maintenance**: Design overlays with future updates in mind

### 2. Resource Management
- **Avoid resource conflicts**: Ensure overlay resources don't conflict with each other
- **Use appropriate data types**: Choose correct resource types (bool, string, integer)
- **Test thoroughly**: Verify overlay behavior across different configurations
- **Monitor performance**: Ensure overlays don't impact system performance

### 3. Build Configuration
- **Use vintf_fragments**: Always include manifest fragments in overlay binaries
- **Specify correct partitions**: Place overlays in appropriate partitions
- **Include in PRODUCT_PACKAGES**: Ensure proper installation and dependencies
- **Test build consistency**: Verify overlays build correctly across different targets

### 4. Priority Management
- **Understand priority hierarchy**: Know which overlay takes precedence
- **Plan overlay interactions**: Consider how multiple overlays interact
- **Use fallback values**: Always provide reasonable default values
- **Document priority decisions**: Clearly document why specific priorities were chosen

## Common Issues and Solutions

### Issue 1: Overlay Not Applied
**Symptoms**: Resource values don't change despite overlay presence

**Possible Causes**:
- Overlay not properly installed
- Resource ID mismatch
- Priority conflict with higher-priority overlay

**Solutions**:
```bash
# Check if overlay is installed and enabled
adb shell cmd overlay list | grep [overlay-name]

# Verify overlay resource mapping
adb shell cmd overlay dump [overlay-name]

# Check overlay installation location
adb shell ls -la /*/overlay/ | grep [overlay-name]
```

### Issue 2: Build Failures
**Symptoms**: Build fails with overlay-related errors

**Common Errors**:
- Missing vintf_fragments
- Resource conflicts
- Incorrect Android.bp configuration

**Solutions**:
- Ensure vintf_fragments are properly included
- Check resource naming conflicts
- Verify Android.bp syntax and dependencies

### Issue 3: Runtime Errors
**Symptoms**: System crashes or unexpected behavior after overlay installation

**Debugging Steps**:
1. Check logcat for overlay-related errors
2. Verify resource types match expected values
3. Test overlay in isolation
4. Check for SELinux policy issues

### Issue 4: Priority Conflicts
**Symptoms**: Wrong overlay takes precedence

**Resolution**:
- Review overlay inheritance chain
- Check partition priorities
- Verify overlay installation locations
- Consider restructuring overlay hierarchy

---

## Forcing Overlay Rebuilds

When developing and testing overlay modifications, Android's build system may not always detect changes that require overlay regeneration. Use the provided clean script to force overlay rebuilds.

### Clean Overlay Build Script

The `clean_overlay_build.sh` script removes overlay-related build artifacts to ensure clean rebuilds:

```bash
# Basic usage (cleans sdk_car_x86_64 by default)
./scripts/clean_overlay_build.sh

# Clean specific target
./scripts/clean_overlay_build.sh sdk_car_arm64

# Show help
./scripts/clean_overlay_build.sh --help
```

### What the Script Cleans

#### 1. Overlay APK Files
- `/system/overlay/`, `/vendor/overlay/`, `/product/overlay/`
- All partition overlay directories in product output

#### 2. Build Intermediates
- Soong intermediate files for overlay compilation
- Car SDK specific overlay intermediates
- SettingsProvider overlay build artifacts

#### 3. System Images
- `system.img`, `vendor.img`, `product.img`
- `super.img`, `system_ext.img` 
- All image intermediates that contain overlays

#### 4. Resource Cache
- AAPT2 compiled resources
- R.java files referencing overlay resources
- Resource compilation cache files

### Typical Workflow

```bash
# 1. Modify overlay XML file
vim device/generic/car/common/overlay/frameworks/base/packages/SettingsProvider/res/values/defaults.xml

# 2. Clean overlay build artifacts
./scripts/clean_overlay_build.sh

# 3. Rebuild
. build/envsetup.sh
lunch sdk_car_x86_64-trunk_staging-userdebug
make -j$(nproc)

# 4. Verify overlay changes
adb shell cmd overlay list | grep settings
adb shell settings get global wifi_on
```

### When to Use Clean Script

- **Overlay XML modifications**: Any changes to overlay resource files
- **Priority changes**: When overlay priority needs recalculation
- **Partition changes**: Moving overlays between partitions
- **Debugging**: When overlays aren't applying as expected
- **Build consistency**: Ensuring clean state for CI/CD
