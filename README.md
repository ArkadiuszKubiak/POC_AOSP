# POC_AOSP: Complete HelloWorld Example for AOSP 14 on Raspberry Pi 4

## Overview

This project demonstrates a complete Andr### 6. ### 6. JNI Native Layerecurity Frameworkid Open Source Project (AOSP) 14 implementation on Raspberry Pi 4, showcasing the full stack integration from kernel driver to Android application. The project follows AOSP architectural best practices and demonstrates modern Android development patterns including AIDL HAL services, SELinux policies, VINTF framework integration, and cross-partition communication.

**Key Features:**
- **Kernel Driver**: Custom sysfs interface for hardware abstraction
- **AIDL HAL Service**: Vendor-specific hardware abstraction layer with service manager registration
- **Dual Communication Approaches**: Both JNI-based and direct Binder implementations
- **Android Application**: Kotlin-based UI demonstrating two different IPC patterns
- **JNI Layer**: Native service discovery and Binder communication implementation
- **Direct Binder Access**: ServiceManager-based AIDL communication without JNI
- **Security Framework**: Complete SELinux policy implementation with cross-partition communication
- **VINTF Integration**: Proper vendor interface framework setup
- **Cross-Platform Documentation**: Includes VIM4 partition management guides

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                 Android Application                      │
│           (Kotlin + Jetpack Compose)                    │
│              Two Communication Paths:                    │
└─────────────┬───────────────────────┬───────────────────┘
              │ Path 1: JNI           │ Path 2: Direct
              │ Interface             │ ServiceManager
┌─────────────┴───────────────────┐   │   ┌───────────────┐
│         JNI Native Layer        │   │   │  AIDL Stub    │
│ (Service Discovery + Binder)    │   │   │ IHelloWorld   │
└─────────────┬───────────────────┘   │   └───────┬───────┘
              │ AIDL Binder IPC       │           │
              └───────────────────────┼───────────┘
                                      │ AIDL Binder IPC
┌─────────────────────────────────────┴───────────────────┐
│                  HAL Service                            │
│        (AIDL + Binder IPC via vndbinder)               │
└─────────────────────┬───────────────────────────────────┘
                      │ sysfs Interface
┌─────────────────────┴───────────────────────────────────┐
│                 Kernel Driver                           │
│              (sysfs /sys/kernel/hello_world)            │
└─────────────────────────────────────────────────────────┘
```

## Project Structure

### HelloWorld/ - Main Implementation
```
HelloWorld/
├── AOSP/                           # AOSP Integration Files
│   ├── device/brcm/rpi4/          # Device Configuration
│   │   └── sepolicy/              # SELinux Security Policies
│   │       ├── hal_brcm_hellowordservice.te
│   │       ├── service_contexts
│   │       └── file_contexts
│   └── vendor/brcm/               # Vendor Partition Components
│       ├── apps/HelloWorld/       # Android Application
│       │   ├── Android.bp         # Build configuration
│       │   ├── AndroidManifest.xml
│       │   ├── hello_world_jni.cpp # JNI Native Interface
│       │   └── src/               # Kotlin Application Source
│       └── interfaces/helloworld/ # HAL Interface Definition
│           ├── aidl/              # AIDL Interface
│           │   ├── Android.bp
│           │   └── vendor/brcm/helloworld/
│           │       └── IHelloWorld.aidl
│           └── default/           # HAL Service Implementation
│               ├── Android.bp
│               ├── HelloWorld.cpp/.h
│               ├── service.cpp    # Service Entry Point
│               ├── vendor.brcm.helloworld-manifest.xml
│               └── vendor.brcm.helloworld-service.rc
└── kernel/                        # Kernel Components
    └── common/drivers/char/
        ├── hello_world_driver.c   # Kernel Driver Implementation
        └── Makefile              # Driver Build Configuration
```

### docs/ - Comprehensive Documentation
```
docs/
├── RBPI4/                         # Raspberry Pi 4 Specific Documentation
│   ├── SELinux_Policy_Documentation.md
│   └── VINTF_Documentation.md
├── VIM4/                          # Khadas VIM4 Documentation
│   └── VIM4_partitions.md
└── emulator/                      # Android Emulator Documentation
    ├── AOSP_CAR_SDK_TARGETS.md
    └── AOSP_RESOURCE_MANAGEMENT.md
```

### scripts/ - Development Tools
```
scripts/
├── flash_interactive.sh          # Interactive Flashing for VIM4
└── clean_overlay_build.sh        # Clean Build Script
```

## Key Components

### 1. Kernel Driver (`hello_world_driver.c`)
- **Purpose**: Provides sysfs interface at `/sys/kernel/hello_world/hello`
- **Functionality**: Write-only sysfs attribute for message passing
- **Security**: Root-only write permissions (mode 0200)
- **Integration**: Uses `device_initcall()` for early initialization

### 2. AIDL HAL Service
- **Interface**: `vendor.brcm.helloworld.IHelloWorld`
- **Implementation**: Bridges sysfs interface to Android framework
- **Communication**: Uses vndbinder for cross-partition IPC
- **Service Registration**: Registers with Android Service Manager
- **VINTF Compliance**: Full VINTF framework integration with manifest

### 3. Android Application
- **UI Framework**: Kotlin with Jetpack Compose featuring dual communication buttons
- **Dual Implementation**: Two separate communication approaches to demonstrate IPC patterns
- **JNI Path**: Complete JNI implementation with service discovery via `HelloWorldNative.sayHelloNative()`
- **Direct Binder Path**: ServiceManager-based communication using `IHelloWorld.Stub.asInterface()`
- **Service Discovery**: Runtime service availability checking with both AServiceManager and ServiceManager
- **Cross-Partition IPC**: Full vndbinder-based communication with vendor HAL service
- **Permissions**: Privileged application with vendor partition access
- **Architecture**: Modern Android development patterns with asynchronous calls for both approaches

### 4. Direct Binder Layer (Kotlin)
- **ServiceManager Access**: Direct access to Android ServiceManager for service discovery
- **AIDL Stub Usage**: Uses generated IHelloWorld.Stub.asInterface() for interface conversion
- **Raw IBinder Handling**: Direct IBinder manipulation without JNI overhead
- **Error Handling**: Comprehensive exception handling for service access and method calls
- **Service Validation**: Runtime service existence checking via ServiceManager.getService()
- **Pure AIDL Communication**: Demonstrates AIDL communication without native code layer

### 5. JNI Native Layer
- **Service Discovery**: Uses AServiceManager_isDeclared() for service availability verification
- **Binder Integration**: AServiceManager_getService() for service binder retrieval
- **AIDL Communication**: IHelloWorld::fromBinder() for interface casting and method invocation
- **Error Handling**: Comprehensive status checking and resource management
- **Logging**: Detailed debug output for troubleshooting Binder communication
- **Cross-Partition Access**: Secure communication between application and vendor HAL service

### 7. Security Framework
- **SELinux Policies**: Complete domain isolation and permission management
- **Service Contexts**: Proper security context mapping
- **File Contexts**: Secure file system labeling
- **Cross-Partition Security**: vndbinder usage for vendor isolation

## Communication Flow

The project demonstrates two complete end-to-end communication approaches:

## Path 1: JNI-Based Communication

### 1. Application Layer (Kotlin)
```kotlin
// JNI button click handler
Button(onClick = { isJniCalling = true }) {
    Text(if (isJniCalling) "Calling..." else "Send via JNI")
}

LaunchedEffect(isJniCalling) {
    val success = withContext(Dispatchers.IO) {
        HelloWorldNative.sayHelloNative(text)  // Call JNI
    }
}
```

### 2. JNI Native Layer (C++)
```cpp
// Service discovery and binder communication
AServiceManager_isDeclared("vendor.brcm.helloworld.IHelloWorld/default")
ndk::SpAIBinder binder(AServiceManager_getService(...))
std::shared_ptr<IHelloWorld> service = IHelloWorld::fromBinder(binder)
ndk::ScopedAStatus status = service->sayHello(message)
```

## Path 2: Direct Binder Communication

### 1. Application Layer (Kotlin)
```kotlin
// Direct AIDL button click handler
Button(onClick = { isBinderCalling = true }) {
    Text(if (isBinderCalling) "Calling..." else "Send via AIDL")
}

LaunchedEffect(isBinderCalling) {
    val serviceName = "vendor.brcm.helloworld.IHelloWorld/default"
    val binder: IBinder? = ServiceManager.getService(serviceName)
    val service: IHelloWorld = IHelloWorld.Stub.asInterface(binder)
    service.sayHello(text)  // Direct AIDL call
}
```

## Common Path: HAL Service & Kernel

### 3. HAL Service Layer (C++)
```cpp
// AIDL interface implementation
ndk::ScopedAStatus HelloWorld::sayHello(const std::string& message) {
    std::ofstream file("/sys/kernel/hello_world/hello");
    file << message;  // Write to kernel interface
}
```

### 4. Kernel Layer (C)
```c
// Sysfs attribute handler
static ssize_t hello_print(struct kobject *kobj, struct kobj_attribute *attr, 
                          const char *buf, size_t count) {
    pr_info("hello_world received: %s\n", buf);  // Kernel logging
}
```

## Build Integration

### AOSP Build System
The project integrates seamlessly with AOSP build system:

```bash
# Add to device.mk
PRODUCT_PACKAGES += \
    vendor.brcm.helloworld-service \
    HelloWorld

# Build targets
m vendor.brcm.helloworld-service  # HAL service
m HelloWorld                      # Android application
```

### Kernel Configuration
```makefile
# Add to kernel configuration
CONFIG_HELLO_WORLD_DRIVER=y
```

## Installation

1. **Copy Project Files**: Place files in corresponding AOSP tree locations
2. **Build Configuration**: Update device.mk and kernel config
3. **Security Policies**: Install SELinux policies to device sepolicy
4. **Build AOSP**: Standard AOSP build process
5. **Flash Device**: Deploy to Raspberry Pi 4

## Development Features

### Dual Communication Implementation
- **JNI Approach**: Traditional Android native development pattern with C++ service access
- **Direct Binder Approach**: Modern Kotlin-based ServiceManager access without JNI overhead
- **Comparative Analysis**: Demonstrates performance and complexity differences between approaches
- **Service Discovery**: Both AServiceManager (NDK) and ServiceManager (Framework) usage patterns
- **Error Handling**: Robust error checking and user feedback for both communication paths
- **Debug Logging**: Comprehensive logging for troubleshooting both JNI and direct Binder issues

### Complete Binder IPC Implementation
- **Service Manager Integration**: Full service discovery and registration
- **Cross-Partition Communication**: Application to vendor HAL service communication
- **AIDL Interface**: Type-safe interface definition with version control
- **Error Handling**: Robust error checking at each communication layer
- **Debug Logging**: Comprehensive logging for troubleshooting

### Cross-Platform Support
- **Primary Target**: Raspberry Pi 4 (Broadcom BCM2711)
- **Documentation**: Extended support for Khadas VIM4
- **Emulator Support**: Android Car SDK targets

### Modern Android Patterns
- **AIDL over HIDL**: Uses modern AIDL interface definition with dual access patterns
- **vndbinder**: Proper vendor partition isolation with both NDK and Framework service access
- **VINTF Framework**: Full compatibility framework integration
- **Jetpack Compose**: Modern UI development with dual button implementation for comparison
- **JNI Best Practices**: Proper resource management and error handling in native layer
- **Framework Integration**: Direct ServiceManager usage demonstrating Android framework patterns

### Security Best Practices
- **SELinux Enforcement**: Mandatory Access Control policies for service communication
- **Partition Isolation**: Vendor/system separation with secure cross-partition IPC
- **Service Discovery**: Secure service manager integration with proper permission checks
- **Permission Model**: Minimal required permissions with privileged application context
- **Binder Security**: vndbinder usage for secure vendor service communication

## Documentation

The project includes extensive documentation covering:

- **VINTF Framework**: Complete vendor interface documentation
- **SELinux Policies**: Security policy implementation guide with binder communication rules
- **Partition Management**: Android partition architecture and cross-partition communication
- **Dual Binder IPC**: Both JNI-based and direct ServiceManager integration patterns
- **AIDL Communication**: Service manager integration and AIDL communication patterns
- **Build Integration**: AOSP build system integration
- **Development Tools**: Scripts for development workflow and debugging
- **Performance Comparison**: Analysis of JNI vs Direct Binder approach trade-offs

## Author Information

**Created by:** Arkadiusz Kubiak  
**Purpose:** Complete AOSP 14 demonstration with dual Binder IPC implementations for Raspberry Pi 4  
**Architecture Focus:** AIDL HAL Services, Dual Communication Patterns, Security Policies, and Modern Android Development  
**LinkedIn:** [www.linkedin.com/in/arkadiusz-kubiak-1b4994150](https://www.linkedin.com/in/arkadiusz-kubiak-1b4994150)

For detailed implementation guides and advanced topics, refer to the comprehensive documentation in the `docs/` directory.

---