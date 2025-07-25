# AOSP Car SDK Target Comparison

This document outlines the differences between the three main Car SDK targets available in AOSP for x86_64 architecture, focusing on target-specific configurations and development considerations.

## Author Information

**Created by:** Arkadiusz Kubiak  
**Purpose:** AOSP Car SDK Target Comparison and Development Guide  
**Architecture Focus:** Android Automotive Development and Multi-Display Systems  
**LinkedIn:** [www.linkedin.com/in/arkadiusz-kubiak-1b4994150](https://www.linkedin.com/in/arkadiusz-kubiak-1b4994150)

---

## Table of Contents
1. [Target Overview](#target-overview)
2. [Detailed Target Comparison](#detailed-comparison)
   - [Standard Car SDK](#1-sdk_car_x86_64-trunk_staging-userdebug)
   - [Multi-Display Car SDK](#2-sdk_car_md_x86_64-trunk_staging-userdebug)
   - [Portrait Car SDK](#3-sdk_car_portrait_x86_64-trunk_staging-userdebug)
3. [Feature Matrix](#feature-matrix)
4. [Hardware Requirements](#hardware-requirements)
5. [Development Recommendations](#development-recommendations)
6. [Build Commands](#build-commands)
7. [Configuration Files](#configuration-files)
8. [Emulator Launch Commands](#emulator-launch-commands)

---

## Target Overview

| Target | Display Configuration | Orientation | Use Case |
|--------|----------------------|-------------|----------|
| `sdk_car_x86_64` | Single display | Landscape | Basic car app development |
| `sdk_car_md_x86_64` | Multi-display | Landscape + Multi | Multi-screen automotive systems |
| `sdk_car_portrait_x86_64` | Single display | Portrait | Vertical screen car systems |

## Detailed Comparison

### 1. `sdk_car_x86_64-trunk_staging-userdebug`
**Standard Car SDK Target**

- **Display**: Single landscape display
- **Features**: Basic automotive functionality
- **Memory footprint**: Smallest
- **Use cases**:
  - Basic car application development
  - Testing core automotive features
  - Resource-constrained development environments

### 2. `sdk_car_md_x86_64-trunk_staging-userdebug`
**Multi-Display Car SDK Target**

- **Display**: Multiple displays (3+ screens)
  - Primary display (driver)
  - Cluster display (instrument panel)
  - Passenger display (entertainment)
- **Configuration**:
  ```makefile
  EMULATOR_MULTIDISPLAY_HW_CONFIG := 1,968,792,160,0,2,1408,792,160,0,3,1408,792,160,0
  BUILD_EMULATOR_CLUSTER_DISPLAY := true
  ENABLE_CLUSTER_OS_DOUBLE := true
  ```
- **Additional features**:
  - Multi-zone audio support
  - Passenger user profiles
  - Secondary home launcher
  - Cross-display application management
- **Use cases**:
  - Multi-display automotive systems
  - Cluster application development
  - Passenger entertainment systems
  - Premium automotive platforms

### 3. `sdk_car_portrait_x86_64-trunk_staging-userdebug`
**Portrait Car SDK Target**

- **Display**: Single portrait display
- **Orientation**: Vertical (portrait mode)
- **Features**: Automotive functionality optimized for tall screens
- **Use cases**:
  - Tesla-style vertical displays
  - Tablet-like car interfaces
  - Modern automotive UI/UX testing

## Feature Matrix

| Feature | Standard | Multi-Display | Portrait |
|---------|----------|---------------|----------|
| **Number of displays** | 1 | 3+ | 1 |
| **Cluster support** | ❌ | ✅ | ❌ |
| **Passenger display** | ❌ | ✅ | ❌ |
| **Multi-zone audio** | ❌ | ✅ | ❌ |
| **Secondary user profiles** | ❌ | ✅ | ❌ |
| **Portrait optimization** | ❌ | ❌ | ✅ |
| **Resource usage** | Low | High | Medium |
| **Build time** | Fast | Slow | Medium |

## Hardware Requirements

### Minimum System Requirements by Target

| Target | RAM | CPU Cores | Disk Space | GPU |
|--------|-----|-----------|------------|-----|
| `sdk_car_x86_64` | 8GB | 4 | 20GB | Basic OpenGL |
| `sdk_car_md_x86_64` | 16GB+ | 8+ | 40GB+ | Dedicated GPU recommended |
| `sdk_car_portrait_x86_64` | 8GB | 4 | 25GB | Basic OpenGL |

## Development Recommendations

### Choose `sdk_car_x86_64` when:
- Starting with basic Car app development
- Testing core automotive APIs
- Working with limited development resources
- Building single-screen applications

### Choose `sdk_car_md_x86_64` when:
- Developing multi-display automotive systems
- Building cluster applications
- Testing passenger entertainment features
- Working on premium automotive platforms
- Need to test cross-display functionality

### Choose `sdk_car_portrait_x86_64` when:
- Targeting vertical car displays
- Building Tesla-style interfaces
- Testing portrait-optimized automotive UX
- Developing for tablet-like car systems

## Build Commands

```bash
# Setup build environment first
. build/envsetup.sh

# Standard Car SDK
lunch sdk_car_x86_64-trunk_staging-userdebug
make -j$(nproc)

# Multi-Display Car SDK
lunch sdk_car_md_x86_64-trunk_staging-userdebug
make -j$(nproc)

# Portrait Car SDK  
lunch sdk_car_portrait_x86_64-trunk_staging-userdebug
make -j$(nproc)
```

## Configuration Files

Each target inherits different configuration files:

- **Standard**: `device/generic/car/sdk_car_x86_64.mk`
- **Multi-Display**: `device/generic/car/common/car_md.mk` + `device/generic/car/sdk_car_x86_64.mk`
- **Portrait**: `device/generic/car/sdk_car_portrait_x86_64.mk`

## Emulator Launch Commands

### Standard Car SDK
```bash
emulator -no-snapshot-load -no-snapshot-save
```

*Note: All targets are based on the trunk_staging branch and built in userdebug mode for development purposes.*
