# AOSP Car SDK Scripts

This directory contains utility scripts for AOSP Car SDK development, focusing on Khadas VIM4 flashing and overlay development workflows.

## Scripts Overview

### 1. `flash_interactive.sh`
**Purpose**: Interactive flashing utility for Khadas VIM4 with AOSP Car SDK  
**Usage**: `./flash_interactive.sh`

**Features**:
- Interactive menu for selecting flash operations
- Partition management (boot, dtb, system, vendor, product)  
- Safety checks and confirmation prompts
- Fastboot mode detection and handling
- Simplified color scheme for better readability

**Requirements**:
- Khadas VIM4 board
- Fastboot/ADB tools installed
- Built AOSP images in `$ANDROID_PRODUCT_OUT`

### 2. `clean_overlay_build.sh`
**Purpose**: Clean overlay build artifacts to force overlay rebuilds  
**Usage**: `./clean_overlay_build.sh [target_name]`

**Features**:
- Cleans overlay APKs from all partitions
- Removes overlay build intermediates  
- Cleans system images containing overlays
- Forces resource recompilation
- Supports multiple Car SDK targets

**Use Cases**:
- After modifying overlay XML files
- When overlays aren't applying correctly
- Debugging overlay priority issues
- Ensuring clean builds for CI/CD

**Examples**:
```bash
# Clean default sdk_car_x86_64 target
./clean_overlay_build.sh

# Clean specific target
./clean_overlay_build.sh sdk_car_arm64

# Show help
./clean_overlay_build.sh --help
```

## Script Dependencies

### Common Requirements
- AOSP source tree properly set up
- Build environment sourced (`. build/envsetup.sh`)
- Lunch target selected (`lunch sdk_car_x86_64-trunk_staging-userdebug`)

### Hardware-Specific Requirements
- **flash_interactive.sh**: Khadas VIM4 board with fastboot access
- **clean_overlay_build.sh**: No hardware dependencies (build environment only)

## Development Workflow

### Typical Overlay Development Cycle
```bash
# 1. Modify overlay resource files
vim device/generic/car/common/overlay/frameworks/base/packages/SettingsProvider/res/values/defaults.xml

# 2. Clean previous build artifacts
./scripts/clean_overlay_build.sh

# 3. Rebuild with changes
. build/envsetup.sh
lunch sdk_car_x86_64-trunk_staging-userdebug  
make -j$(nproc)

# 4. Flash to device (if using VIM4)
./scripts/flash_interactive.sh

# 5. Verify overlay application
adb shell cmd overlay list | grep settings
adb shell settings get global wifi_on
```

### Typical VIM4 Flashing Cycle  
```bash
# 1. Build AOSP images
make -j$(nproc)

# 2. Flash to VIM4
./scripts/flash_interactive.sh

# 3. Boot and test
# Device should boot with applied overlays
```

## Script Maintenance

### Adding New Scripts
1. Create script in `/scripts/` directory
2. Make executable: `chmod +x script_name.sh`
3. Add documentation to this README
4. Update relevant project documentation

### Color Scheme Standards
All scripts use simplified ANSI color codes:
- `RED`: Error messages and warnings
- `GREEN`: Success messages and confirmations  
- `YELLOW`: Important information and prompts
- `BLUE`: Section headers and informational messages
- `NC`: Reset to default color

### Error Handling Standards
- Use `set -euo pipefail` for strict error handling
- Provide meaningful error messages with context
- Include cleanup procedures for partial failures
- Validate prerequisites before executing main logic

## Related Documentation

- **Overlay Development**: `../docs/AOSP_RESOURCE_MANAGEMENT.md`
- **VIM4 Partitioning**: `../docs/VIM4_partitions.md`  
- **Car SDK Targets**: `../docs/AOSP_CAR_SDK_TARGETS.md`
- **SELinux Policies**: `../docs/SELinux_Policy_Documentation.md`

## Troubleshooting

### Common Issues

#### Script Permission Denied
```bash
# Fix: Make script executable
chmod +x scripts/script_name.sh
```

#### AOSP Environment Not Sourced
```bash
# Fix: Source build environment
. build/envsetup.sh
lunch sdk_car_x86_64-trunk_staging-userdebug
```

#### VIM4 Not in Fastboot Mode
```bash
# Fix: Put device in fastboot mode manually
# Hold power + function buttons during boot
```

#### Clean Script Fails - No Target Directory
```bash
# Fix: Specify correct target or build first
./clean_overlay_build.sh your_actual_target
# or
make -j$(nproc)  # Build target first
```

## Contributing

When contributing new scripts:

1. Follow existing code style and error handling patterns
2. Include comprehensive help text (`--help` flag)
3. Add input validation and prerequisite checks
4. Update this README with script documentation
5. Test scripts on clean AOSP environment

---

*This directory is part of the AOSP Car SDK documentation and development workflow. For more information, see the main project documentation.*
