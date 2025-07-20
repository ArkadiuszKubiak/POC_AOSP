# AOSP Development Scripts

**Author**: Arkadiusz Kubiak  
**LinkedIn**: https://www.linkedin.com/in/arkadiusz-kubiak-1b4994150

This directory contains utility scripts for AOSP development and device flashing workflows.

## Scripts Overview

### 1. clean_overlay_build.sh
**Purpose**: Clean overlay builds for AOSP Car SDK development

This script forces a rebuild of overlays and system images after overlay modifications. It's designed specifically for AOSP Car SDK development where overlay changes need to be properly integrated into the build system.

**Key Features**:
- Cleans overlay-related build artifacts
- Forces system image regeneration
- Supports configurable target builds
- Includes safety checks for AOSP environment
- Color-coded output for better visibility

**Usage**:
```bash
./clean_overlay_build.sh [target_name]
./clean_overlay_build.sh sdk_car_x86_64
```

### 2. flash_interactive.sh
**Purpose**: Interactive Android image flashing tool for Khadas VIM4

This script provides an interactive interface for flashing Android images to the Khadas VIM4 development board. It simplifies the flashing process with automatic detection of required modes and comprehensive diagnostics.

**Key Features**:
- Interactive file selection interface
- Automatic fastboot/fastbootd mode detection
- A/B partition support
- Dynamic partition handling (super.img)
- Bootloader unlock verification
- Comprehensive device diagnostics
- Color-coded output with progress feedback
- Robust error handling and troubleshooting

**Usage**:
```bash
./flash_interactive.sh
```

## Prerequisites

- AOSP build environment properly configured
- Fastboot tools installed and accessible
- Khadas VIM4 device connected (for flashing script)
- Appropriate USB drivers installed

## Notes

Both scripts include comprehensive error handling and user guidance. They are designed to be run from the AOSP root directory and include environment validation checks.

For detailed usage instructions and troubleshooting, refer to the comments within each script file.
