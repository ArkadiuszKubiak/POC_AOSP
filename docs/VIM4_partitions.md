# Android IMG Files Analysis for Khadas VIM4

## Overview

This repository contains comprehensive analysis and documentation for Android .img files used in flashing Khadas VIM4 devices. The project focuses on Project Treble architecture, dynamic partitions, and modern Android partition management.

## Author Information

**Created by:** Arkadiusz Kubiak  
**Purpose:** Analysis of Android .img files for Khadas VIM4  
**Architecture Focus:** Project Treble and Dynamic Partitions

For more information about Android flashing and development, feel free to contact the author.

## What Are Partitions? - Technical Overview

### Definition
Partitions are logical divisions of physical storage media (eMMC, UFS, NVMe) that create separate, isolated storage areas. Each partition acts as an independent filesystem container with its own addressing space, filesystem type, and access permissions.

### Technical Implementation
```
Physical Storage Layout:
┌─────────────────────────────────────────────────────────────┐
│                    Physical Storage Device                   │
│                         (8GB eMMC)                          │
├─────────────┬─────────────┬─────────────┬─────────────────────┤
│ Partition 1 │ Partition 2 │ Partition 3 │    Free Space      │
│  (boot)     │  (system)   │  (vendor)   │                    │
│   64MB      │   787MB     │   229MB     │       ~6.9GB       │
└─────────────┴─────────────┴─────────────┴─────────────────────┘
     LBA 0-131071  LBA 131072-  LBA 1742847-  LBA 2210815-
                   1742846      2210814      16777215
```

### Key Technical Concepts

#### 1. **Partition Table Types**
- **GPT (GUID Partition Table)** - Modern standard, supports >2TB, 128 partitions
- **MBR (Master Boot Record)** - Legacy standard, limited to 4 primary partitions
- **Android uses GPT** for all modern devices

#### 2. **Addressing Schemes**
- **LBA (Logical Block Addressing)** - Sequential block numbering (512-byte blocks)
- **CHS (Cylinder-Head-Sector)** - Legacy geometric addressing
- **Physical vs Logical** - Wear leveling in flash storage

#### 3. **Partition Types & UUIDs**
```bash
# Android-specific partition type GUIDs
Boot partition:     C12A7328-F81F-11D2-BA4B-00A0C93EC93B
System partition:   EBD0A0A2-B9E5-4433-87C0-68B6B72699C7
Vendor partition:   EBD0A0A2-B9E5-4433-87C0-68B6B72699C7
```

#### 4. **Storage Stack Architecture**
```
Application Layer        │ /system /vendor /data
├────────────────────────┼─────────────────────────
VFS (Virtual File System)│ ext4, f2fs, vfat
├────────────────────────┼─────────────────────────
Block Layer              │ /dev/block/mmcblk0p1
├────────────────────────┼─────────────────────────
Device Mapper (optional) │ dm-linear, dm-verity
├────────────────────────┼─────────────────────────
Hardware Layer           │ eMMC Controller, NAND Flash
```

### Android-Specific Partition Characteristics

#### **Read-Only System Partitions**
- Mounted with `ro` flag for security
- Integrity protected by dm-verity
- Immutable during runtime operation

#### **Dynamic vs Static Partitions**
- **Static:** Fixed size defined at build time
- **Dynamic:** Resizable logical partitions within super partition
- **Super partition:** Container for multiple logical partitions

#### **Verified Boot Integration**
- Each partition has cryptographic hash tree
- Boot-time verification prevents tampering
- vbmeta.img contains verification metadata

### Storage Device Communication

#### **eMMC Protocol Stack**
```
┌─────────────────┐
│   Android OS    │
├─────────────────┤
│   Block Layer   │ ← /dev/block/mmcblk0pX
├─────────────────┤
│   MMC Subsystem │ ← Kernel driver
├─────────────────┤
│   eMMC Protocol │ ← CMD/ACMD commands
├─────────────────┤
│   Hardware Bus  │ ← 8-bit parallel interface
└─────────────────┘
```

#### **Common eMMC Commands**
- `CMD23` - Set Block Count
- `CMD25` - Write Multiple Blocks  
- `CMD18` - Read Multiple Blocks
- `CMD6` - Switch (partition access)

### Partition Naming Conventions

#### **Block Device Naming**
```bash
/dev/block/mmcblk0     # eMMC device 0
/dev/block/mmcblk0p1   # Partition 1 on eMMC device 0
/dev/block/by-name/system  # Symbolic link to system partition
```

#### **Android Partition Labels**
- Consistent across devices for compatibility
- Defined in Device Tree or partition table
- Used by fastboot and recovery tools

### Performance Considerations

#### **Alignment Requirements**
- **4KB alignment** - Standard page size
- **Erase block alignment** - Optimal for NAND flash
- **Performance penalty** for misaligned I/O

#### **Wear Leveling Impact**
- Flash translation layer (FTL) in eMMC controller
- Logical-to-physical address mapping
- Hidden from OS - handled by hardware

This technical foundation is essential for understanding how Android manages storage and why specific partition layouts are designed for optimal performance and security on devices like the Khadas VIM4.

## Project Treble Architecture

### Introduction

Android Treble is a revolutionary architecture introduced in Android 8.0 (API 26) that fundamentally changed how Android systems are organized.

#### Problem Before Treble:
- Monolithic system structure
- Vendor-specific code mixed with Android Framework
- Difficulties in system updates
- Every manufacturer had to adapt entire Android to their hardware
- Long waiting time for updates

#### Treble Solution:
- Separation of Android Framework from vendor-specific code
- Introduction of Vendor Interface (VINTF)
- Standardization of Hardware Abstraction Layer (HAL)
- Independent updates of system and vendor code

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    ANDROID FRAMEWORK                        │
│                   (system.img)                              │
├─────────────────────────────────────────────────────────────┤
│                  VENDOR INTERFACE                           │
│                     (VINTF)                                 │
├─────────────────────────────────────────────────────────────┤
│                   VENDOR PARTITION                          │
│     (vendor.img - HAL, drivers, firmware)                  │
└─────────────────────────────────────────────────────────────┘
```

### Key Treble Partitions

- **system.img** - Android Framework, system apps, libraries
- **vendor.img** - Hardware-specific drivers, HAL implementations
- **product.img** - Product-specific apps and customizations
- **system_ext.img** - System extensions that can be updated
- **odm.img** - Original Design Manufacturer customizations

## Vendor Interface (VINTF) Details

VINTF is the compatibility layer between Android Framework and Vendor HAL implementations.

### VINTF Components:
- Vendor Interface Object (VINTF Object) - runtime compatibility checker
- Manifest files - describe available HAL services
- Compatibility matrices - define required/optional HAL versions
- Framework Compatibility Matrix (FCM) - framework requirements
- Device Manifest - vendor HAL implementations

### HAL Interface Evolution:
- **HIDL** (Hardware Interface Definition Language) - Android 8.0+
- **AIDL** (Android Interface Definition Language) - Android 11+
- **Passthrough HAL** - legacy compatibility mode
- **Binderized HAL** - modern IPC communication

### Debugging Commands

#### Check HAL Services:
```bash
# List all running HAL services
adb shell lshal

# List HAL services with types
adb shell lshal -t

# Check HIDL services (Android 8+)
adb shell lshal | grep @

# Check AIDL services (Android 11+)
adb shell lshal | grep -v @

# Check specific HAL service
adb shell lshal | grep camera
```

#### VINTF Compatibility:
```bash
# Check system compatibility
adb shell vintf

# Verify vendor compatibility
adb shell vintf --check-compat

# Get framework requirements
adb shell vintf --get-framework-matrix

# Get device manifest
adb shell vintf --get-device-manifest
```

## IMG Files Categorization

### 1. Essential System Files (Always Required)

| File | Size | Description |
|------|------|-------------|
| `boot.img` | 64M | System kernel and ramdisk |
| `system.img` | 787M | Main Android system |
| `vendor.img` | 229M | Device-specific files |
| `vbmeta.img` | 8K | System verification metadata |
| `userdata.img` | 2.2M | User data partition (optional) |

### 2. Bootloader and Firmware Files

| File | Size | Description |
|------|------|-------------|
| `bootloader.img` | 4M | U-Boot bootloader |
| `dtb.img` | 262K | Device Tree Blob |
| `dtbo.img` | 2M | Device Tree Overlay |
| `logo.img` | 894K | Boot logo |

### 3. System Extension Files

| File | Size | Description |
|------|------|-------------|
| `product.img` | 187M | Product apps and components |
| `system_ext.img` | 136M | System extensions |
| `odm.img` | 536K | ODM modifications |
| `odm_ext.img` | 16M | ODM extensions |
| `oem.img` | 32M | OEM partition |

### 4. DLKM Files (Dynamic Loadable Kernel Modules)

| File | Size | Description |
|------|------|-------------|
| `vendor_dlkm.img` | 13M | Vendor kernel modules |
| `system_dlkm.img` | 468K | System kernel modules |
| `odm_dlkm.img` | 340K | ODM kernel modules |

### 5. Special Boot Files

| File | Size | Description |
|------|------|-------------|
| `init_boot.img` | 8M | Boot initialization (Android 13+) |
| `vendor_boot.img` | 64M | Vendor boot partition |
| `vbmeta_system.img` | 4K | System verification metadata |
| `ramdisk.img` | 2.4M | Main ramdisk |

### 6. Auxiliary/Optional Files

| File | Size | Description |
|------|------|-------------|
| `super.img` | 1.4G | Super partition with dynamic partitions |
| `update.img` | 1.6G | Full update image |
| `vendor-bootconfig.img` | 111B | Vendor boot configuration |
| `super_empty.img` | 5K | Empty super partition |

## Flashing Recommendations

### Minimum Required (Basic System):
1. `bootloader.img` - bootloader
2. `dtb.img` - device tree
3. `boot.img` - kernel + ramdisk
4. `vbmeta.img` - verification metadata
5. `system.img` - main system
6. `vendor.img` - device files
7. `userdata.img` - user data

### Recommended (Full System):
8. `dtbo.img` - device tree overlay
9. `product.img` - product apps
10. `system_ext.img` - system extensions
11. `odm.img` - ODM modifications
12. `logo.img` - boot logo

### Optional (Advanced Features):
13. `init_boot.img` - boot initialization (Android 13+)
14. `vendor_boot.img` - vendor boot
15. `vbmeta_system.img` - system verification
16. `*_dlkm.img` - kernel modules
17. `odm_ext.img` - ODM extensions
18. `oem.img` - OEM partition

### Alternative (Super Partition):
- `super.img` - single file containing all dynamic partitions

## Khadas VIM4 Bootloader Unlock

### Prerequisites for Flashing
Before flashing any partitions on Khadas VIM4, the bootloader must be unlocked to allow fastboot operations.

### Bootloader Unlock Procedure

#### Required Hardware:
- **USB to TTL Converter** - CH340 or similar serial tool
- **Jumper Wires** - For GPIO connections
- **Terminal Software** - minicom, PuTTY, or similar

#### Hardware Connection Setup:

**Serial Tool Pin Mapping:**
```
Serial Tool Pin  →  VIM4 GPIO Header Pin  →  Function
GND              →  Pin 17               →  Ground
TXD (Blue)       →  Pin 18               →  Linux_Rx
RXD (Orange)     →  Pin 19               →  Linux_Tx
VCC(3.3V)        →  Pin 20               →  Power (optional)
```

**Physical Connection:**
```
┌─────────────────┐    ┌─────────────────────────────────┐
│   USB-TTL       │    │         VIM4 GPIO Header        │
│   Converter     │    │                                 │
│                 │    │  17(GND)  18(Rx)  19(Tx)  20   │
│  GND ───────────┼────┤    │       │       │       │    │
│  TXD ───────────┼────┤────────────┼───────┼───────┼    │
│  RXD ───────────┼────┤────────────────────┼───────┼    │
│  VCC ───────────┼────┤────────────────────────────┼    │
│                 │    │                                 │
└─────────────────┘    └─────────────────────────────────┘
```

#### Serial Communication Settings:

**VIM4 Configuration:**
- **Baudrate:** 921600 (specific to VIM4/VIM1S)
- **Data Bits:** 8
- **Parity:** None
- **Stop Bits:** 1
- **Flow Control:** None

#### Step-by-Step Process:

**1. Setup Serial Connection:**
```bash
# Install serial communication software (Linux example):
sudo apt install minicom screen

# Connect using minicom:
sudo minicom -D /dev/ttyUSB0 -b 921600

# Alternative using screen:
sudo screen /dev/ttyUSB0 921600

# Windows: Use PuTTY with COM port and 921600 baud
```

**2. Enter U-Boot Console:**
```bash
# Power on VIM4 while connected to serial console
# Watch for U-Boot boot messages
# Press any key when you see boot countdown to interrupt boot process
# You should see U-Boot prompt: kvim4#

Hit any key to stop autoboot:  3
kvim4#
```

**2. Unlock Bootloader:**

#### Understanding U-Boot Environment Variables

U-Boot (Universal Bootloader) uses environment variables to control various aspects of the boot process. These variables are stored in persistent storage and control hardware initialization, security features, and boot behavior.

#### Command-by-Command Analysis:

**`kvim4# setenv lock 0` - Bootloader Lock Control**

**What it is:**
- `lock` is a U-Boot environment variable that controls the bootloader's security lock state
- This is a hardware-level security mechanism implemented in the bootloader firmware
- Acts as the primary gatekeeper for allowing unsigned or modified firmware to be flashed

**Technical Implementation:**
```c
// U-Boot bootloader source (pseudo-code)
int check_bootloader_lock(void) {
    char *lock_status = env_get("lock");
    if (lock_status && (strcmp(lock_status, "0") == 0)) {
        return BOOTLOADER_UNLOCKED;  // Allow custom firmware
    }
    return BOOTLOADER_LOCKED;        // Reject unsigned firmware
}
```

**What it controls:**
- **Fastboot commands:** When `lock=1`, fastboot refuses to flash unsigned partitions
- **Custom recovery:** Locked bootloader prevents booting unsigned recovery images
- **Kernel modification:** Blocks loading of unsigned kernel images
- **System partition writes:** Prevents modification of critical system partitions

**Security implications:**
- **`lock=1` (default):** Maximum security - only manufacturer-signed images accepted
- **`lock=0` (unlocked):** Development mode - any firmware can be flashed
- Used by manufacturers to prevent unauthorized firmware modifications

---

**`kvim4# setenv avb2 0` - Android Verified Boot 2.0 Control**

**What it is:**
- `avb2` controls Android Verified Boot 2.0 (AVB) verification system
- AVB is Google's cryptographic boot verification framework
- Ensures the entire boot chain (bootloader → kernel → system) is authentic and unmodified

**Technical Architecture:**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Bootloader    │    │   vbmeta.img    │    │  System Images  │
│                 │    │                 │    │                 │
│ - Root of Trust │────▶│ - Hash Trees    │────▶│ - boot.img     │
│ - Public Keys   │    │ - Signatures    │    │ - system.img    │
│ - AVB Library   │    │ - Rollback      │    │ - vendor.img    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

**AVB Verification Process:**
1. **Bootloader** reads `vbmeta.img` containing cryptographic metadata
2. **Hash verification** checks integrity of each partition using Merkle trees
3. **Signature verification** validates authenticity using manufacturer's public key
4. **Rollback protection** prevents downgrade to vulnerable firmware versions
5. **Boot decision** - proceed if all verifications pass, halt if they fail

**What `avb2=0` disables:**
```c
// Simplified AVB check in bootloader
if (env_get_yesno("avb2") == 1) {
    AvbSlotVerifyResult verify_result;
    verify_result = avb_slot_verify(ops, requested_partitions, 
                                   ab_suffix, flags, &slot_data);
    if (verify_result != AVB_SLOT_VERIFY_RESULT_OK) {
        printf("AVB verification failed!\n");
        return -1;  // Halt boot process
    }
}
// If avb2=0, skip all verification and boot directly
```

**Components affected by AVB:**
- **Hash tree verification:** Disabled - tampered partitions won't be detected
- **Signature checking:** Bypassed - unsigned images will be accepted
- **Rollback protection:** Disabled - older vulnerable firmware can be installed
- **Root of trust:** Compromised - device cannot guarantee firmware authenticity

---

**`kvim4# saveenv` - Environment Persistence**

**What it is:**
- `saveenv` commits all current environment variables to persistent storage
- Without this command, changes exist only in RAM and are lost on reboot
- Critical step to make bootloader modifications permanent

**Storage locations (device-specific):**
```bash
# Common U-Boot environment storage locations:
# eMMC/SD: Dedicated environment partition (usually 128KB)
# SPI Flash: Reserved area in bootloader region
# NAND Flash: Specific blocks marked as environment storage

# VIM4 typically uses eMMC environment partition:
# /dev/mmcblk0p1 or similar dedicated partition
```

**Technical process:**
```c
// U-Boot environment save process (simplified)
int saveenv(void) {
    // 1. Serialize all environment variables to binary format
    env_data = env_export();
    
    // 2. Calculate CRC32 checksum for integrity
    crc = crc32(0, env_data, ENV_SIZE);
    
    // 3. Write to persistent storage (eMMC partition)
    storage_write(ENV_PARTITION_OFFSET, env_data, ENV_SIZE);
    
    // 4. Verify write operation
    return verify_env_write();
}
```

**What happens without `saveenv`:**
- Environment changes remain in volatile RAM only
- Next reboot restores previous environment values
- Bootloader lock and AVB settings revert to defaults
- All unlock attempts are lost

---

**`kvim4# reset` - System Restart**

**What it is:**
- `reset` command performs a hardware reset of the entire system
- Equivalent to power cycling the device
- Forces bootloader to restart with new environment variables

**Technical implementation:**
```c
// U-Boot reset command implementation
void do_reset(cmd_tbl_t *cmdtp, int flag, int argc, char * const argv[]) {
    // 1. Disable interrupts
    disable_interrupts();
    
    // 2. Flush caches
    flush_cache_all();
    
    // 3. Trigger hardware reset via system control registers
    // Method varies by SoC (System on Chip)
    arch_reset_cpu();  // Platform-specific reset mechanism
    
    // 4. Infinite loop (should never reach here)
    while(1);
}
```

**Platform-specific reset mechanisms:**
```c
// For ARM-based SoCs like Amlogic S905X4 (VIM4)
void arch_reset_cpu(void) {
    // Write to hardware reset register
    writel(RESET_MAGIC_VALUE, WATCHDOG_RESET_REG);
    // OR
    writel(RESET_MAGIC_VALUE, SYSTEM_CONTROL_RESET_REG);
}
```

**Why reset is necessary:**
- **Environment reload:** Bootloader re-reads environment from persistent storage
- **Clean state:** Ensures all subsystems restart with new configuration
- **Lock verification:** Next boot will respect the new `lock=0` and `avb2=0` settings
- **Memory clearing:** Removes any cached security states from previous boot

---

#### Complete Security Model Overview

**Before unlocking (`lock=1`, `avb2=1`):**
```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│ Signed Only │────▶│ AVB Verified │────▶│ Secure Boot │
│ Firmware    │    │ Chain        │    │ Process     │
└─────────────┘    └──────────────┘    └─────────────┘
      ▲                     ▲                  ▲
      │                     │                  │
  Rejects unsigned      Hash & signature   System integrity
  custom firmware       verification       guaranteed
```

**After unlocking (`lock=0`, `avb2=0`):**
```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│ Any         │────▶│ No           │────▶│ Development │
│ Firmware    │    │ Verification │    │ Mode Boot   │
└─────────────┘    └──────────────┘    └─────────────┘
      ▲                     ▲                  ▲
      │                     │                  │
  Accepts any           No security        Custom ROM
  custom firmware       checks             development
```

#### Environment Variables Deep Dive

**View all environment variables:**
```bash
kvim4# printenv              # Show all variables
kvim4# printenv lock         # Show specific variable
kvim4# printenv avb2         # Show AVB status
```

**Other security-related variables:**
```bash
kvim4# printenv secure_boot  # Hardware secure boot status
kvim4# printenv verified     # Overall verification status  
kvim4# printenv rollback     # Rollback protection level
```

#### Bootloader Environment Storage Structure

```
┌─────────────────────────────────────────────────────────┐
│                U-Boot Environment Partition              │
├─────────────────────────────────────────────────────────┤
│ CRC32 Checksum (4 bytes)                               │
├─────────────────────────────────────────────────────────┤
│ Variable 1: lock=0\0                                    │
├─────────────────────────────────────────────────────────┤
│ Variable 2: avb2=0\0                                    │
├─────────────────────────────────────────────────────────┤
│ Variable 3: bootcmd=run fastboot_key\0                  │
├─────────────────────────────────────────────────────────┤
│ ... (other environment variables)                       │
├─────────────────────────────────────────────────────────┤
│ \0\0 (End marker)                                       │
└─────────────────────────────────────────────────────────┘
```

This comprehensive understanding of these commands is essential for anyone working with Android bootloader unlocking and custom firmware development on devices like the Khadas VIM4.

**3. Enter Fastboot Mode:**
```bash
# From host computer (new terminal):
arek# adb reboot bootloader               # Enter fastboot mode
```

**4. Switch to Fastbootd:**

#### Understanding Fastboot vs Fastbootd

**What is Fastbootd?**
Fastbootd is the userspace implementation of the fastboot protocol that runs within Android's recovery environment. Unlike traditional bootloader fastboot, fastbootd operates at a higher level and provides advanced partition management capabilities.

#### Technical Architecture Comparison

```
┌─────────────────────────────────────────────────────────────────┐
│                    Bootloader Fastboot                         │
├─────────────────────────────────────────────────────────────────┤
│ • Runs in bootloader (U-Boot)                                  │
│ • Limited partition support                                    │
│ • Static partition flashing only                               │
│ • No dynamic partition awareness                               │
│ • Direct hardware access                                       │
└─────────────────────────────────────────────────────────────────┘
                               ↓
                    fastboot reboot fastboot
                               ↓
┌─────────────────────────────────────────────────────────────────┐
│                     Fastbootd (Userspace)                      │
├─────────────────────────────────────────────────────────────────┤
│ • Runs in Android recovery environment                         │
│ • Full dynamic partition support                               │
│ • Super partition management                                   │
│ • Logical partition resizing                                   │
│ • Advanced Android-aware operations                            │
└─────────────────────────────────────────────────────────────────┘
```

#### Why Switch to Fastbootd?

**Limitations of Bootloader Fastboot:**
```c
// Bootloader fastboot limitations
typedef struct {
    partition_support_t static_only;        // Only fixed-size partitions
    super_partition_t unsupported;          // Cannot handle super partition
    logical_partitions_t unavailable;       // No logical partition awareness
    resize_operations_t impossible;         // Cannot resize partitions
    metadata_management_t limited;          // Basic partition table only
} bootloader_fastboot_t;
```

**Fastbootd Capabilities:**
```c
// Fastbootd advanced features
typedef struct {
    partition_support_t dynamic_aware;      // Handles logical partitions
    super_partition_t fully_supported;      // Complete super partition management
    logical_partitions_t available;         // Can create/delete logical partitions
    resize_operations_t supported;          // Real-time partition resizing
    metadata_management_t advanced;         // LP metadata manipulation
    android_integration_t complete;         // Full Android system awareness
} fastbootd_capabilities_t;
```

#### Technical Implementation Details

**Fastbootd Boot Process:**
```cpp
// system/core/fastboot/device/main.cpp
int main(int argc, char* argv[]) {
    // 1. Initialize recovery environment
    RecoveryUI* ui = device_ui();
    
    // 2. Mount essential partitions
    ensure_path_mounted("/metadata");
    ensure_path_mounted("/data");
    
    // 3. Initialize fastboot daemon
    FastbootDevice fastboot_device;
    
    // 4. Start USB gadget for communication
    if (!fastboot_device.StartFastbootd()) {
        LOG(ERROR) << "Failed to start fastbootd";
        return -1;
    }
    
    // 5. Enter command loop
    return fastboot_device.Main();
}
```

**Super Partition Management:**
```cpp
// system/core/fastboot/device/commands.cpp
bool FastbootDevice::FlashPartition(const std::string& partition_name,
                                   const std::vector<char>& data) {
    // Check if partition is logical (in super partition)
    if (android::fs_mgr::IsLogicalPartition(partition_name)) {
        // Use libdm for dynamic partition operations
        auto& dm = android::dm::DeviceMapper::Instance();
        
        // Resize logical partition if needed
        if (!ResizeLogicalPartition(partition_name, data.size())) {
            return false;
        }
        
        // Flash to logical partition
        return FlashLogicalPartition(partition_name, data);
    }
    
    // Fall back to traditional partition flashing
    return FlashPhysicalPartition(partition_name, data);
}
```

#### Command Execution and Transition

```bash
# Switch to fastbootd from bootloader fastboot
arek# fastboot reboot fastboot      # Switch to userspace fastboot (fastbootd)
```

**What happens during this command:**

1. **Bootloader Receives Command:**
   ```c
   // U-Boot fastboot implementation
   void fastboot_reboot_fastboot(void) {
       // Set boot target to recovery/fastbootd
       env_set("boot_fastbootd", "1");
       
       // Trigger system reboot
       do_reset(NULL, 0, 0, NULL);
   }
   ```

2. **Recovery Boot Process:**
   ```bash
   # Device boots into recovery mode with fastbootd flag
   U-Boot → Recovery Kernel → Recovery Ramdisk → Fastbootd daemon
   ```

3. **Fastbootd Initialization:**
   ```cpp
   // Recovery init starts fastbootd
   if (boot_into_fastbootd) {
       // Mount necessary partitions
       mount_metadata_partition();
       mount_system_partitions();
       
       // Start fastbootd service
       start_fastbootd_daemon();
   }
   ```

#### Partition Support Comparison

**Bootloader Fastboot Supported Partitions:**
```bash
# Traditional static partitions only
fastboot flash bootloader bootloader.img    ✓ Supported
fastboot flash dtb dtb.img                  ✓ Supported  
fastboot flash boot boot.img                ✓ Supported
fastboot flash vbmeta vbmeta.img            ✓ Supported

# Dynamic partitions - LIMITED or UNSUPPORTED
fastboot flash system system.img            ✗ May fail on dynamic systems
fastboot flash vendor vendor.img            ✗ May fail on dynamic systems
fastboot flash product product.img          ✗ Usually unsupported
```

**Fastbootd Supported Partitions:**
```bash
# All partition types supported
fastboot flash system system.img            ✓ Full support + resizing
fastboot flash vendor vendor.img            ✓ Full support + resizing
fastboot flash product product.img          ✓ Full support + resizing
fastboot flash system_ext system_ext.img    ✓ Full support + resizing
fastboot flash odm odm.img                  ✓ Full support + resizing

# Advanced operations
fastboot create-logical-partition system_b 2147483648    ✓ Logical partition creation
fastboot delete-logical-partition product_a              ✓ Logical partition deletion
fastboot resize-logical-partition vendor_b 536870912     ✓ Real-time resizing
```

#### Verification and Status Check

**Check Current Fastboot Mode:**
```bash
# Verify you're in fastbootd (not bootloader fastboot)
arek# fastboot getvar is-userspace
# Should return: is-userspace: yes

# Check fastbootd version
arek# fastboot getvar version
# Should return: version: fastbootd-<android_version>

# List available logical partitions
arek# fastboot getvar super-partition-name
# Should return: super-partition-name: super

# Check dynamic partition support
arek# fastboot getvar dynamic-partition
# Should return: dynamic-partition: true
```

#### Practical Example: Dynamic Partition Flashing

**Before (Bootloader Fastboot - Limited):**
```bash
# May fail on devices with dynamic partitions
arek# fastboot flash system system.img
FAILED (remote: 'Partition not found or insufficient space')
```

**After (Fastbootd - Full Support):**
```bash
# Seamless flashing with automatic resizing
arek# fastboot reboot fastboot           # Switch to fastbootd
arek# fastboot flash system system.img   # Automatically resizes logical partition
Resizing 'system' partition to 2048MB...
Flashing 'system' partition...
OKAY [  45.123s]
finished. total time: 45.123s
```

#### Error Handling and Troubleshooting

**Common Issues:**
```bash
# Device doesn't support fastbootd
arek# fastboot reboot fastboot
FAILED (remote: 'Command not supported')
# Solution: Device has older Android version without fastbootd support

# Fastbootd fails to start
arek# fastboot reboot fastboot
# Device reboots but fastboot commands fail
# Solution: Check USB drivers, cable connection, or recovery partition corruption
```

**Debug Commands:**
```bash
# Check if device is in fastbootd mode
arek# fastboot devices
1234567890abcdef	fastbootd    # Note "fastbootd" suffix

# If showing "fastboot" instead of "fastbootd":
1234567890abcdef	fastboot     # Still in bootloader mode

# Force fastbootd mode (alternative method)
arek# fastboot reboot recovery
# Then manually select "Enter fastboot" from recovery menu
```

#### Performance and Capabilities

**Fastbootd Advantages:**
```
• Dynamic partition support: Can handle super partition and logical volumes
• Real-time resizing: Adjusts partition sizes automatically during flashing
• Metadata awareness: Understands LP (Logical Partition) metadata format
• Android integration: Access to Android's storage management APIs
• Error recovery: Better error handling and recovery mechanisms
• Modern protocol: Supports latest fastboot protocol extensions
```

**Use Cases Requiring Fastbootd:**
```
1. Flashing Android 10+ devices with dynamic partitions
2. Custom ROM installation on modern devices
3. Partition layout modifications
4. Super partition management
5. A/B slot operations on logical partitions
6. GSI (Generic System Image) flashing
```

This transition to fastbootd is essential for modern Android development and represents the evolution from simple bootloader-based flashing to sophisticated userspace partition management.

#### Verification:
```bash
# Verify bootloader is unlocked:
arek# fastboot getvar unlocked
# Should return: unlocked: yes

# Check available partitions:
arek# fastboot getvar all
```

#### Flash Example:
```bash
# Now you can flash partitions:
arek# fastboot flash product product.img
arek# fastboot flash system system.img
arek# fastboot flash vendor vendor.img
```

### Important Notes:

#### **Security Implications:**
- Unlocking bootloader **disables verified boot** security features
- Device becomes vulnerable to malicious firmware modifications
- **Warranty may be voided** by manufacturer

#### **Environment Variables:**
- `lock=0` - Disables bootloader lock mechanism
- `avb2=0` - Disables Android Verified Boot 2.0 verification
- Changes persist across reboots until manually changed

#### **Recovery Options:**
```bash
# To re-lock bootloader (if needed):
kvim4# setenv lock 1
kvim4# setenv avb2 1
kvim4# saveenv
kvim4# reset
```

#### **Troubleshooting:**
- **No U-Boot prompt:** 
  - Check serial connection and pin mapping
  - Verify correct baudrate (921600 for VIM4)
  - Ensure jumper wires are properly connected
  - Try different USB ports or USB-TTL converters
- **Fastboot not recognized:** 
  - Ensure proper USB drivers installed
  - Check USB cable connection
  - Verify device appears in `lsusb` (Linux) or Device Manager (Windows)
- **Flash failures:** 
  - Verify bootloader unlock status with `fastboot getvar unlocked`
  - Check partition names with `fastboot getvar all`
  - Ensure sufficient power supply to VIM4

#### **Serial Communication Troubleshooting:**
```bash
# Linux: Check available serial devices
ls /dev/ttyUSB* /dev/ttyACM*

# Check if device is detected
dmesg | grep -i usb
dmesg | grep -i ch340

# Add user to dialout group (logout/login required)
sudo usermod -a -G dialout $USER
```

This unlock procedure is **mandatory** for custom ROM development and partition analysis on Khadas VIM4 devices.

## Flashing Sequence

1. `bootloader.img` (fastboot mode)
2. `dtb.img` (fastboot mode)
3. `boot.img` (fastboot mode)
4. `vbmeta.img` (fastboot mode)
5. Reboot to fastbootd: `fastboot reboot fastboot`
6. `system.img` (fastbootd mode)
7. `vendor.img` (fastbootd mode)
8. `product.img` (fastbootd mode)
9. Remaining partitions (fastbootd mode)
10. `userdata.img` (fastbootd mode) - optional

## Partition Sizes

- **Essential files:** ~1.3GB
- **Recommended files:** ~1.7GB
- **All files:** ~2.0GB
- **Super partition:** 1.4GB (replaces most dynamic partitions)

## Treble Benefits for Khadas VIM4

- Easier Android OS updates
- Vendor (Khadas) can independently update drivers
- Ability to use Generic System Images (GSI)
- Better support for custom ROM
- Modular system - easier development

## GSI (Generic System Images) Support

- Ability to flash generic Android on Khadas VIM4
- `vendor.img` remains preserved (drivers, HAL)
- `system.img` can be replaced with generic GSI
- Example: AOSP GSI + Khadas `vendor.img` = working system

## Security Considerations

- `vbmeta.img` - Android Verified Boot 2.0
- Contains hash trees of all partitions
- Integrity verification during boot
- Can be disabled: `fastboot --disable-verity --disable-verification`

## Architecture Evolution

- **Pre-Treble:** Monolithic system partition
- **Treble (Android 8+):** system + vendor separation
- **Dynamic Partitions (Android 10+):** super partition
- **DLKM (Android 11+):** dynamic kernel modules
- **Mainline modules:** more frequent kernel updates

## AOSP Partition Management Architecture

### Overview

AOSP manages partitions through multiple layers, from bootloader initialization to runtime partition operations. This section explains how Android handles partition management at the code level.

### 1. Bootloader and Early Boot

**U-Boot/Bootloader Level:**
- Partitions are defined in Device Tree Blob (DTB)
- U-Boot reads partition table from eMMC/UFS storage
- Bootloader passes partition information to kernel via command line

```c
// Example partition definition in Device Tree
partitions {
    boot {
        reg = <0x0 0x4000000>;  // offset, size
        label = "boot";
    };
    system {
        reg = <0x4000000 0x40000000>;
        label = "system";
    };
};
```

### 2. Kernel Level - Block Layer

**Partition Parser:**
```c
// fs/partitions/core.c
struct parsed_partitions *check_partition(struct gendisk *hd, 
                                         struct block_device *bdev)
{
    // Detects partition table type (GPT, MBR)
    // Parses partition metadata
    // Creates data structures for each partition
}
```

**GPT Parser:**
```c
// fs/partitions/efi.c
int efi_partition(struct parsed_partitions *state)
{
    // Reads GPT header
    // Parses GPT entries
    // Verifies checksums
    // Registers partitions in the system
}
```

### 3. Android Init Process

**fstab.hardware Configuration:**
```bash
# /vendor/etc/fstab.khadas_vim4
/dev/block/by-name/system    /system    ext4    ro,barrier=1    wait,slotselect
/dev/block/by-name/vendor    /vendor    ext4    ro,barrier=1    wait,slotselect
/dev/block/by-name/userdata  /data      ext4    defaults        wait,check
```

**Init Mount Process:**
```cpp
// system/core/init/mount_handler.cpp
bool DoMount(const FstabEntry& entry) {
    // Waits for block device availability
    // Verifies filesystem
    // Mounts partition at appropriate location
    // Sets system properties
}
```

### 4. Dynamic Partitions (Super Partition)

**liblp (libpartition) Management:**
```cpp
// system/core/fs_mgr/liblp/builder.cpp
class MetadataBuilder {
    // Manages super partition metadata
    bool AddPartition(const std::string& name, uint64_t size);
    bool ResizePartition(const std::string& name, uint64_t size);
    bool RemovePartition(const std::string& name);
};
```

**Super Partition Layout:**
```
┌─────────────────┐
│   LP Metadata   │ ← Logical partition metadata
├─────────────────┤
│   system.img    │ ← Logical partition
├─────────────────┤
│   vendor.img    │ ← Logical partition  
├─────────────────┤
│   product.img   │ ← Logical partition
├─────────────────┤
│   Free Space    │ ← Available space
└─────────────────┘
```

### 5. Fastboot and Flashing Operations

**Fastboot Protocol Implementation:**
```cpp
// system/core/fastboot/fastboot.cpp
void flash_partition(const std::string& partition, const std::string& filename) {
    // Opens .img file
    // Checks partition size
    // Sends data over USB/TCP
    // Verifies write operation
}
```

**Fastbootd (Userspace Fastboot):**
```cpp
// system/core/fastboot/device/commands.cpp
bool FlashPartition(const std::string& partition_name,
                   const std::vector<char>& data) {
    // Uses libdm (device-mapper) for dynamic partitions
    // Can resize logical partitions
    // Updates super partition metadata
}
```

### 6. Device Mapper for Dynamic Partitions

**dm-linear mapping:**
```cpp
// kernel/drivers/md/dm-linear.c
// Maps logical partitions to physical blocks
static int linear_map(struct dm_target *ti, struct bio *bio)
{
    // Translates logical offset to physical
    // Redirects I/O to appropriate device
}
```

**libdm Interface:**
```cpp
// system/core/fs_mgr/libdm/dm.cpp
bool CreateDevice(const std::string& name,
                 const DmTable& table) {
    // Creates device-mapper mapping
    // Registers new block device
    // /dev/block/mapper/system_a
}
```

### 7. Runtime Partition Management APIs

**Storage Manager Framework:**
```java
// frameworks/base/core/java/android/os/storage/StorageManager.java
public class StorageManager {
    // Manages mount/unmount operations
    // Monitors partition status
    // Notifies applications of changes
}
```

**Vold (Volume Daemon):**
```cpp
// system/vold/VolumeManager.cpp
class VolumeManager {
    // Daemon managing volumes
    // Handles encryption/decryption
    // Manages adoptable storage
}
```

### 8. A/B Partitioning (Seamless Updates)

**Update Engine Boot Control:**
```cpp
// system/update_engine/common/boot_control_interface.h
class BootControlInterface {
    virtual bool SetActiveBootSlot(unsigned int slot) = 0;
    virtual unsigned int GetCurrentSlot() = 0;
    // Switches between slot A and slot B
}
```

**Slot Management Architecture:**

#### What is A/B Partitioning?

A/B partitioning, also known as "seamless updates" or "dual-boot partitioning," is a sophisticated update mechanism introduced in Android 7.0 (Nougat). It maintains two complete copies of critical system partitions on the device, allowing updates to be installed in the background while the device continues to operate normally.

#### Technical Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Physical Storage Layout                      │
├─────────────────────────────────────────────────────────────────┤
│ Slot A Partitions        │        Slot B Partitions            │
├─────────────────────────────────────────────────────────────────┤
│ boot_a     │ system_a    │ boot_b     │ system_b                │
│ vendor_a   │ dtbo_a      │ vendor_b   │ dtbo_b                  │
│ vbmeta_a   │ product_a   │ vbmeta_b   │ product_b               │
└─────────────────────────────────────────────────────────────────┘
```

**Current State Example:**
```
Active Slot: A (device boots from and runs on Slot A)
Inactive Slot: B (receives updates, ready for next boot)

┌─────────────────┐    ┌─────────────────┐
│   SLOT A        │    │   SLOT B        │
│   (ACTIVE)      │    │   (INACTIVE)    │
├─────────────────┤    ├─────────────────┤
│ ✓ Running OS    │    │ ○ Updated OS    │
│ ✓ User Apps     │    │ ○ New Apps      │
│ ✓ System Data   │    │ ○ Ready to Boot │
└─────────────────┘    └─────────────────┘
```

#### Why Two Slots? - Problem-Solution Analysis

**Traditional Update Problems (Pre-A/B):**

1. **Device Unusable During Updates:**
   ```
   Update Process: Device OFF → Flash partitions → Reboot → Hope it works
   Risk: Brick device if update fails or power loss occurs
   ```

2. **Single Point of Failure:**
   ```
   ┌─────────────────┐
   │ Single System   │ ← If update corrupts this, device is bricked
   │ Partition       │
   └─────────────────┘
   ```

3. **No Rollback Capability:**
   ```
   Bad Update → Corrupted System → Factory Reset Required → Data Loss
   ```

**A/B Solution Benefits:**

1. **Seamless Updates:**
   ```
   Update Process: Device ON → Background update to inactive slot → 
                   Quick reboot → Switch slots → Continue using device
   ```

2. **Automatic Rollback:**
   ```
   ┌─────────────────┐    ┌─────────────────┐
   │ Known Good      │    │ Updated System  │
   │ System (Slot A) │◄───┤ (Slot B)        │
   └─────────────────┘    └─────────────────┘
            ▲                       │
            │                       ▼
            └─── Auto rollback if boot fails
   ```

3. **Zero Downtime:**
   ```
   User Experience: Normal usage → Brief reboot → Updated system
   No waiting, no "Installing update..." screens
   ```

#### Technical Implementation Details

**Partition Duplication:**
```c
// Example partition layout for A/B system
typedef struct {
    // Critical system partitions (duplicated)
    partition_t boot_a, boot_b;           // Kernel + ramdisk
    partition_t system_a, system_b;       // Android framework
    partition_t vendor_a, vendor_b;       // HAL implementations
    partition_t vbmeta_a, vbmeta_b;       // Verification metadata
    partition_t dtbo_a, dtbo_b;           // Device tree overlays
    
    // Shared partitions (not duplicated)
    partition_t userdata;                 // User apps and data
    partition_t metadata;                 // Partition metadata
    partition_t bootloader;               // Bootloader itself
} ab_partition_layout_t;
```

**Slot State Management:**
```c
// Boot control interface implementation
typedef struct {
    uint8_t priority;        // Boot priority (0-15, higher = more important)
    uint8_t tries_remaining; // Retry attempts before marking as unbootable
    uint8_t successful_boot; // 1 if slot booted successfully
    uint8_t verity_corrupted; // 1 if dm-verity detected corruption
} slot_metadata_t;

// Example slot states
slot_metadata_t slot_a = {
    .priority = 15,          // Highest priority
    .tries_remaining = 7,    // Maximum retries
    .successful_boot = 1,    // Last boot was successful
    .verity_corrupted = 0    // No corruption detected
};

slot_metadata_t slot_b = {
    .priority = 14,          // Lower priority (inactive)
    .tries_remaining = 7,    // Ready for use
    .successful_boot = 0,    // Not yet booted
    .verity_corrupted = 0    // Clean state
};
```

#### Update Process Flow

**Step-by-Step A/B Update Process:**

1. **Update Detection:**
   ```
   Update Engine → Checks for updates → Downloads OTA package
   ```

2. **Background Installation:**
   ```cpp
   // Update engine installs to inactive slot
   bool InstallUpdate() {
       inactive_slot = GetInactiveSlot();  // Get slot B if A is active
       
       // Install new system.img to system_b
       FlashPartition("system_" + inactive_slot, new_system_image);
       
       // Install new vendor.img to vendor_b  
       FlashPartition("vendor_" + inactive_slot, new_vendor_image);
       
       // Update boot partition
       FlashPartition("boot_" + inactive_slot, new_boot_image);
       
       return true;
   }
   ```

3. **Slot Switch Preparation:**
   ```cpp
   // Mark new slot as bootable
   bool PrepareSlotSwitch() {
       SetSlotAsUnbootable(current_slot);     // Mark current slot lower priority
       SetSlotAsBootable(inactive_slot);      // Mark updated slot higher priority
       SetSlotAsActive(inactive_slot);        // Set as next boot target
       
       return true;
   }
   ```

4. **Reboot and Verification:**
   ```cpp
   // Bootloader boot decision logic
   int SelectBootSlot() {
       slot_a_priority = GetSlotPriority(SLOT_A);
       slot_b_priority = GetSlotPriority(SLOT_B);
       
       if (slot_a_priority > slot_b_priority && IsSlotBootable(SLOT_A)) {
           return SLOT_A;
       } else if (IsSlotBootable(SLOT_B)) {
           return SLOT_B;
       }
       
       return SLOT_INVALID;  // No bootable slots - recovery mode
   }
   ```

5. **Boot Success Verification:**
   ```cpp
   // Android init process
   void VerifyBootSuccess() {
       if (IsFirstBootAfterUpdate()) {
           // System boots successfully
           MarkBootSuccessful(GetCurrentSlot());
           
           // Optional: Mark old slot as unbootable to save space
           // SetSlotAsUnbootable(GetInactiveSlot());
       }
   }
   ```

#### Failure Handling and Rollback

**Automatic Rollback Scenarios:**

1. **Boot Failure Detection:**
   ```cpp
   // Bootloader retry logic
   int AttemptBoot(int slot) {
       tries_remaining = GetSlotTriesRemaining(slot);
       
       if (tries_remaining > 0) {
           DecrementSlotTries(slot);
           return BootFromSlot(slot);
       } else {
           // Mark slot as unbootable
           SetSlotAsUnbootable(slot);
           return TryAlternateSlot();
       }
   }
   ```

2. **System Corruption Detection:**
   ```cpp
   // dm-verity corruption handling
   void HandleVerityCorruption() {
       current_slot = GetCurrentSlot();
       
       // Mark current slot as corrupted
       SetSlotVerityCorrupted(current_slot);
       SetSlotAsUnbootable(current_slot);
       
       // Trigger reboot to alternate slot
       TriggerRebootToAlternateSlot();
   }
   ```

3. **User-Space Failure Recovery:**
   ```cpp
   // Update engine watchdog
   void MonitorSystemHealth() {
       if (DetectSystemFailure()) {
           // System is unstable after update
           RollbackToKnownGoodSlot();
           NotifyUserOfRollback();
       }
   }
   ```

#### Storage and Performance Implications

**Storage Requirements:**
```
Traditional Single Slot: 100% storage for system partitions
A/B Dual Slot:          200% storage for system partitions

Example calculation:
- system.img: 2GB × 2 = 4GB
- vendor.img: 500MB × 2 = 1GB  
- boot.img: 64MB × 2 = 128MB
- Total overhead: ~2.5GB additional storage required
```

**Performance Characteristics:**
```
Update Download:     Same as traditional (background)
Update Installation: Faster (no device downtime)
Update Application:  ~10 seconds (just reboot time)
Rollback Time:       ~10 seconds (automatic on boot failure)
```

#### Real-World Example: VIM4 A/B Layout

```bash
# Typical A/B partition layout on Khadas VIM4
/dev/block/by-name/boot_a        # Kernel + ramdisk (Slot A)
/dev/block/by-name/boot_b        # Kernel + ramdisk (Slot B)
/dev/block/by-name/system_a      # Android framework (Slot A)
/dev/block/by-name/system_b      # Android framework (Slot B)  
/dev/block/by-name/vendor_a      # HAL implementations (Slot A)
/dev/block/by-name/vendor_b      # HAL implementations (Slot B)
/dev/block/by-name/vbmeta_a      # Verification metadata (Slot A)
/dev/block/by-name/vbmeta_b      # Verification metadata (Slot B)

# Shared partitions (no duplication needed)
/dev/block/by-name/userdata      # User data and applications
/dev/block/by-name/metadata      # Partition metadata
/dev/block/by-name/misc          # Recovery communication
/dev/block/by-name/bootloader    # U-Boot bootloader
```

#### Development and Testing Benefits

**For Developers:**
```
- Safe testing: Flash experimental builds to inactive slot
- Quick recovery: Always have working system in other slot
- Bisecting bugs: Easy to switch between builds
- Continuous integration: Automated testing with rollback
```

**For Manufacturers:**
```
- Reduced support costs: Fewer bricked devices
- Faster deployment: Updates without service interruption  
- Better user experience: No "updating" downtime
- Quality assurance: Automatic rollback on failures
```

This A/B partitioning system represents a fundamental shift in how Android handles system updates, providing unprecedented reliability and user experience improvements while enabling more aggressive update deployment strategies.

### 9. File System Management Layer

**fs_mgr (File System Manager):**
```cpp
// system/core/fs_mgr/fs_mgr.cpp
int fs_mgr_mount_all(struct fstab *fstab) {
    // Mounts all partitions from fstab
    // Handles different filesystems (ext4, f2fs)
    // Verifies dm-verity
}
```

**Verity/Integrity Verification:**
```cpp
// system/core/fs_mgr/fs_mgr_verity.cpp
int load_verity_table(const std::string& device,
                     const std::string& name) {
    // Loads hash tree for integrity verification
    // Uses device-mapper verity target
}
```

### 10. Build System Integration

**BoardConfig.mk Partition Definitions:**
```makefile
# Partition definitions in build system
BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 3221225472
BOARD_VENDORIMAGE_PARTITION_SIZE := 536870912

# Dynamic partitions configuration
BOARD_SUPER_PARTITION_SIZE := 6442450944
BOARD_SUPER_PARTITION_GROUPS := khadas_dynamic_partitions
```

**Image Creation Process:**
```python
# build/tools/releasetools/build_image.py
def BuildImage(in_dir, prop_dict, out_file):
    # Creates .img file from directory
    # Sets partition size
    # Adds filesystem metadata
```

### Partition Management Flow

1. **Boot Phase:** U-Boot → Kernel → Init
2. **Discovery:** Kernel parses GPT → Creates /dev/block/by-name/*
3. **Mounting:** Init reads fstab → fs_mgr mounts partitions
4. **Runtime:** Storage Manager + Vold manage volumes
5. **Updates:** Update Engine + Fastboot handle updates

### Key Components Interaction

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Applications  │    │  System Server  │    │  Update Engine  │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          v                      v                      v
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Storage Manager │    │      Vold       │    │   Fastbootd     │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          v                      v                      v
┌─────────────────────────────────────────────────────────────────┐
│                           fs_mgr                                │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          v
┌─────────────────────────────────────────────────────────────────┐
│                     Device Mapper                              │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          v
┌─────────────────────────────────────────────────────────────────┐
│                  Block Layer (Kernel)                        │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          v
┌─────────────────────────────────────────────────────────────────┐
│                  Hardware (eMMC/UFS)                           │
└─────────────────────────────────────────────────────────────────┘
```

This architecture provides a comprehensive, layered approach to partition management in AOSP, ensuring reliability, security, and flexibility for modern Android devices like the Khadas VIM4.

## Files

- `README.md` - This documentation file

## Contributing

Feel free to contribute improvements to the analysis script or documentation.

## License

This project is provided for educational and development purposes.
