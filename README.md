# POC_AOSP: Hello World Example for AOSP 14 on Raspberry Pi 4

## Overview

This project is a complete "Hello World" demonstration for Android Open Source Project (AOSP) 14, targeting the Raspberry Pi 4 (rbpi4) platform. It showcases the integration of a custom kernel driver, a Hardware Abstraction Layer (HAL) service, an AIDL interface, and a privileged Android application. The folder structure strictly follows the AOSP 14 tree for rbpi4, making it easy to merge with your existing AOSP source tree.

**Additional Resources:**  
This project includes comprehensive documentation covering SELinux policies, VINTF framework integration, partition management for VIM4, and practical implementation guides.

**To run this example:**  
Replace the corresponding files in your AOSP tree for rbpi4 with those from this project, preserving the directory structure.

## Author Information

**Created by:** Arkadiusz Kubiak  
**Purpose:** Hello World example for AOSP 14 on Raspberry Pi 4  
**Architecture Focus:** AIDL HAL Services, JNI Integration, and SELinux Policies  
**LinkedIn:** [www.linkedin.com/in/arkadiusz-kubiak-1b4994150](https://www.linkedin.com/in/arkadiusz-kubiak-1b4994150)

For more information about AOSP development and HAL services, feel free to contact the author.

---

## Documentation

This project includes extensive technical documentation:

### 📚 Available Documentation

- **[SELinux Policy Documentation](docs/SELinux_Policy_Documentation.md)** - Comprehensive guide to SELinux policies for HAL services, including security domains, type enforcement, and troubleshooting
- **[VINTF Framework Documentation](docs/VINTF_Documentation.md)** - Detailed documentation of the Vendor Interface framework, compatibility mechanisms, and HAL service registration
- **[VIM4 Partition Analysis](docs/VIM4_partitions.md)** - In-depth analysis of Android IMG files, Project Treble architecture, dynamic partitions, and AOSP partition management for Khadas VIM4

### 🔧 Utilities

- **[Flash Interactive Script](scripts/flash_interactive.sh)** - Interactive tool for selective flashing of IMG files to devices
- **[WiFi Overlay Tools](scripts/)** - Diagnostic and management scripts for WiFi overlay configurations

---

## Component Overview

### 1. Kernel Driver

- **Path:** `HelloWorld/kernel/common/drivers/char/hello_world_driver.c`
- **Description:** Implements a simple character driver that creates a sysfs entry `/sys/kernel/hello_world/hello`. Messages sent from user space are logged in the kernel log.
- **Features:**
  - Uses `device_initcall()` for automatic initialization
  - Creates `/sys/kernel/hello_world/hello` sysfs interface
  - Write-only permissions (0200) for root access
  - Comprehensive error handling and logging

### 2. HAL Service

- **Path:** `HelloWorld/AOSP/vendor/brcm/interfaces/helloworld/default/`
- **Description:** Implements the AIDL HAL service (`vendor.brcm.helloworld-service`). The service receives messages from clients and writes them to the kernel driver via sysfs.
- **Components:**
  - **HelloWorld.cpp/.h** - Service implementation
  - **service.cpp** - Main service entry point
  - **Android.bp** - Build configuration
  - **VINTF Manifest** - Service declaration for framework compatibility
  - **Init Script (.rc)** - Service startup configuration

### 3. AIDL Interface

- **Path:** `HelloWorld/AOSP/vendor/brcm/interfaces/helloworld/aidl/vendor/brcm/helloworld/IHelloWorld.aidl`
- **Description:** Defines the AIDL interface for communication between the Android app and the HAL service.
- **Features:**
  - `@VintfStability` annotation for framework compatibility
  - Simple `sayHello(String message)` method
  - Vendor-specific namespace (`vendor.brcm.helloworld`)

#### AIDL Versioning and API Freezing

AIDL versioning is managed using the `aidl_api` folder, which contains frozen snapshots of your AIDL interface to ensure backward compatibility and stability.

- **Current API Path:** `HelloWorld/AOSP/vendor/brcm/interfaces/helloworld/aidl/aidl_api/vendor.brcm.helloworld/current/`
- **Frozen Versions:** `HelloWorld/AOSP/vendor/brcm/interfaces/helloworld/aidl/aidl_api/vendor.brcm.helloworld/1/`
- **Description:** Contains immutable frozen versions of the AIDL interface. These files should not be edited manually.

**How to generate and freeze the AIDL API:**
1. Create or modify the AIDL file (e.g., `IHelloWorld.aidl`) as needed.
2. Run the following command in your AOSP build environment to generate or update the API:
   ```sh
   m vendor.brcm.helloworld-update-api
   ```
   This will create or update the API files in the `aidl_api` directory.
3. After generating the API, freeze it to prevent further changes:
   ```sh
   m vendor.brcm.helloworld-freeze-api
   ```
4. Commit the changes in the `aidl_api` folder to your repository to ensure the API version is tracked.

**Note:**  
Frozen AIDL APIs guarantee that clients depending on your interface will not break due to incompatible changes. Always generate and freeze the API before releasing or integrating with other modules.

### 4. Android Application

- **Path:** `HelloWorld/AOSP/vendor/brcm/apps/HelloWorld/`
- **Description:** Privileged Android app with a modern Jetpack Compose UI to send messages to the HAL service. Uses JNI to communicate with the HAL.
- **Features:**
  - **Kotlin/Compose UI** - Modern Android UI framework
  - **JNI Integration** - Native bridge to HAL service
  - **Asynchronous Processing** - Non-blocking UI operations
  - **Error Handling** - Comprehensive error reporting
- **Components:**
  - **MainActivity.kt** - Main activity with Compose UI
  - **HelloWorldNative.kt** - Native method declarations
  - **hello_world_jni.cpp** - JNI implementation
  - **AndroidManifest.xml** - App configuration
  - **Android.bp** - Build configuration

### 5. SELinux Policy

- **Path:** `HelloWorld/AOSP/device/brcm/rpi4/sepolicy/`
- **Description:** SELinux type enforcement and file contexts for the HAL service.
- **Components:**
  - **hal_brcm_hellowordservice.te** - Type enforcement rules
  - **file_contexts** - File security context mappings
  - **service_contexts** - Service security context definitions

### 6. Device Integration

- **Path:** `HelloWorld/AOSP/device/brcm/rpi4/device.mk`
- **Description:** Adds the HAL service and HelloWorld app to the build.
- **Includes:** HAL service binary, Android app, and required dependencies

---

## Project Structure

```
POC_AOSP/
├── README.md                                    # This file
├── docs/                                        # Technical documentation
│   ├── SELinux_Policy_Documentation.md          # SELinux security policies guide
│   ├── VINTF_Documentation.md                   # Vendor Interface framework guide
│   └── VIM4_partitions.md                       # Android partition analysis
├── HelloWorld/                                  # Main project implementation
│   ├── AOSP/                                    # Android userspace components
│   │   ├── device/brcm/rpi4/                    # Device-specific configurations
│   │   │   ├── device.mk                        # Build integration
│   │   │   └── sepolicy/                        # SELinux policies
│   │   │       ├── file_contexts                # File security contexts
│   │   │       ├── hal_brcm_hellowordservice.te # Type enforcement rules
│   │   │       └── service_contexts             # Service security contexts
│   │   └── vendor/brcm/                         # Vendor-specific components
│   │       ├── apps/HelloWorld/                 # Android application
│   │       │   ├── Android.bp                   # App build configuration
│   │       │   ├── AndroidManifest.xml          # App manifest
│   │       │   ├── hello_world_jni.cpp          # JNI implementation
│   │       │   └── src/com/example/helloworld/  # Kotlin source code
│   │       └── interfaces/helloworld/           # HAL interface and service
│   │           ├── aidl/                        # AIDL interface definition
│   │           │   ├── Android.bp               # Interface build config
│   │           │   ├── aidl_api/                # Versioned API snapshots
│   │           │   │   └── vendor.brcm.helloworld/
│   │           │   │       ├── 1/               # Frozen version 1
│   │           │   │       └── current/         # Current development version
│   │           │   └── vendor/brcm/helloworld/
│   │           │       └── IHelloWorld.aidl     # Interface definition
│   │           └── default/                     # HAL service implementation
│   │               ├── Android.bp               # Service build config
│   │               ├── HelloWorld.cpp/.h        # Service implementation
│   │               ├── service.cpp              # Service entry point
│   │               ├── vendor.brcm.helloworld-manifest.xml  # VINTF manifest
│   │               └── vendor.brcm.helloworld-service.rc    # Init script
│   └── kernel/common/drivers/char/              # Kernel components
│       ├── hello_world_driver.c                 # Kernel driver implementation
│       └── Makefile                             # Kernel build configuration
└── scripts/                                     # Utility scripts
    ├── flash_interactive.sh                     # Interactive flashing tool
    ├── remove_wifion_overlay.sh                 # WiFi overlay removal
    └── wifi_overlay_diagnostics.sh              # WiFi diagnostics
```

---

## How to Integrate and Run

### Prerequisites

- **AOSP Android 14** source tree configured for Raspberry Pi 4
- **AOSP Kernel** source tree with driver support
- Proper build environment setup (Ubuntu 22.04+ recommended)
- Fastboot and ADB tools installed

### Integration Steps

### File Integration Guide

| Component | Source Path | Target Path | Action |
|-----------|-------------|-------------|--------|
| Kernel Driver | `HelloWorld/kernel/common/drivers/char/` | `<kernel>/drivers/char/` | Copy + Update Makefile |
| Device Config | `HelloWorld/AOSP/device/brcm/rpi4/` | `<aosp>/device/brcm/rpi4/` | Copy/Merge |
| HAL Service | `HelloWorld/AOSP/vendor/brcm/interfaces/` | `<aosp>/vendor/brcm/interfaces/` | Copy |
| Android App | `HelloWorld/AOSP/vendor/brcm/apps/` | `<aosp>/vendor/brcm/apps/` | Copy |
| SELinux Policies | `HelloWorld/AOSP/device/brcm/rpi4/sepolicy/` | `<aosp>/device/brcm/rpi4/sepolicy/` | Copy/Merge |

**Note:** Always backup existing files before integration. Some files may need to be merged rather than replaced, especially `device.mk` and SELinux policy files.

---

## Technical Highlights

### Architecture Features

- **VINTF Compatibility** - Full Vendor Interface framework integration
- **Modern AIDL** - Uses `@VintfStability` for interface stability
- **SELinux Security** - Comprehensive security policy implementation
- **Jetpack Compose UI** - Modern Android UI framework
- **Asynchronous Processing** - Non-blocking user interface operations

### Communication Flow

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Android App   │    │   JNI Bridge    │    │   HAL Service   │    │  Kernel Driver  │
│   (Kotlin UI)   │    │     (C++)       │    │   (AIDL C++)    │    │      (C)        │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ • User Input    │───▶│ • Service Lookup│───▶│ • AIDL Method   │───▶│ • Sysfs Write   │
│ • Compose UI    │    │ • Binder IPC    │    │ • File I/O      │    │ • Kernel Log    │
│ • Error Display │◀───│ • Status Return │◀───│ • Error Handle  │◀───│ • Data Process  │
└─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Security Model

- **Process Isolation** - Each component runs in isolated security domains
- **File Access Control** - Restricted sysfs access via SELinux policies  
- **Service Authentication** - VINTF manifest validation
- **IPC Security** - Vendor binder with proper context labeling

---

## Troubleshooting

### Common Issues

#### Kernel Driver Not Loading
```bash
# Check kernel configuration
adb shell cat /proc/config.gz | gunzip | grep CONFIG_SYSFS

# Verify driver initialization
adb shell dmesg | grep hello_world

# Check sysfs permissions
adb shell ls -la /sys/kernel/hello_world/
```

#### HAL Service Not Starting
```bash
# Check service status
adb shell service list | grep vendor.brcm.helloworld

# Verify SELinux contexts
adb shell ls -Z /vendor/bin/hw/vendor.brcm.helloworld-service

# Check service logs
adb logcat -s vendor.brcm.helloworld-service
```

#### App Connection Issues
```bash
# Verify service declaration
adb shell service check vendor.brcm.helloworld.IHelloWorld/default

# Check app permissions
adb shell dumpsys package com.example.helloworld

# Review SELinux denials
adb shell dmesg | grep avc
```

### Debug Commands

```bash
# Monitor real-time kernel logs
adb shell dmesg -w | grep hello_world

# Test sysfs interface manually
adb shell 'echo "test message" > /sys/kernel/hello_world/hello'

# Check VINTF compatibility
adb shell vintf check

# Service manager debugging
adb shell dumpsys servicemanager
```

---

## License

This project is licensed under the MIT License.  
You are free to use, modify, and distribute this software for any purpose, including commercial and private use.

See the [LICENSE](LICENSE) file for the full text of the MIT License.