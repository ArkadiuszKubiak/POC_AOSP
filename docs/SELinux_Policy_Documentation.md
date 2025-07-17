# SELinux Policy Documentation for HelloWorld HAL Service

## Table of Contents
1. [SELinux Overview](#selinux-overview)
2. [Android SELinux Architecture](#android-selinux-architecture)
3. [HelloWorld HAL Service Policy Analysis](#helloworld-hal-service-policy-analysis)
4. [File-by-File Analysis](#file-by-file-analysis)
5. [Policy Rules Explanation](#policy-rules-explanation)
6. [Security Model](#security-model)
7. [Troubleshooting](#troubleshooting)

## SELinux Overview

### What is SELinux?

**Security-Enhanced Linux (SELinux)** is a mandatory access control (MAC) system implemented in the Linux kernel. Unlike traditional discretionary access control (DAC) systems where users control access to their own files, SELinux enforces system-wide security policies that cannot be overridden by users.

### Key SELinux Concepts

#### 1. **Mandatory Access Control (MAC)**
- System enforces security policy regardless of user permissions
- Even root cannot bypass SELinux restrictions
- Policies are defined by security administrators, not file owners

#### 2. **Security Contexts**
Every process, file, and resource has a security context with format:
```
user:role:type:level
```

**Example:** `u:object_r:hal_brcm_hellowordservice_exec:s0`
- `u` - SELinux user
- `object_r` - Role for objects/files
- `hal_brcm_hellowordservice_exec` - Type (most important for Android)
- `s0` - MLS/MCS security level

#### 3. **Types and Domains**
- **Type**: Security classification for files and objects
- **Domain**: Security classification for processes
- **Type Enforcement**: Core SELinux mechanism that controls access

#### 4. **Policy Language**
```selinux
allow source_type target_type:object_class permissions;
```

**Example:**
```selinux
allow hal_brcm_hellowordservice vendor_file:file { read open };
```
- `hal_brcm_hellowordservice` can `read` and `open` files of type `vendor_file`

## Android SELinux Architecture

### Android SELinux Evolution

#### Android 4.3 (2013): SELinux Introduction
- **Permissive Mode**: SELinux logs violations but doesn't block them
- Primary goal: Identify potential security issues

#### Android 4.4 (2014): Enforcing Mode
- **Enforcing Mode**: SELinux actively blocks policy violations
- Limited to core system processes

#### Android 5.0+ (2014): Full Enforcement
- SELinux enforced for all processes
- Introduction of domain isolation

#### Android 8.0+ (2017): Treble and Enhanced SELinux
- **Vendor/System Separation**: Different policy domains
- **HIDL HAL Services**: Strict isolation between framework and vendor
- **Vendor Interface (VINTF)**: Standardized HAL communication

### Android SELinux Architecture Layers

```
┌─────────────────────────────────────────────────┐
│                 APPLICATIONS                    │ ← untrusted_app domain
├─────────────────────────────────────────────────┤
│              ANDROID FRAMEWORK                  │ ← system_server domain
├─────────────────────────────────────────────────┤
│                  HAL SERVICES                   │ ← hal_* domains
├─────────────────────────────────────────────────┤
│               VENDOR SERVICES                   │ ← vendor_* domains
├─────────────────────────────────────────────────┤
│                LINUX KERNEL                     │ ← kernel domain
└─────────────────────────────────────────────────┘
```

### Key Android SELinux Concepts

#### 1. **Domain Isolation**
Each process type runs in isolated security domain:
- `system_server` - Android Framework
- `hal_*` - Hardware Abstraction Layer services
- `vendor_*` - Vendor-specific services
- `untrusted_app` - User applications

#### 2. **Neverallow Rules**
Compile-time rules that prevent dangerous permissions:
```selinux
neverallow untrusted_app system_file:file execute;
```

#### 3. **Attributes**
Group related types together:
```selinux
attribute hal_service;  # Groups all HAL services
attribute vendor_service;  # Groups vendor services
```

## HelloWorld HAL Service Policy Analysis

### Service Architecture Overview

Our HelloWorld HAL service follows Android's standard architecture:

```
┌─────────────────────┐    ┌──────────────────────┐    ┌─────────────────────┐
│   CLIENT PROCESS    │    │   SERVICE MANAGER    │    │  HELLOWORLD SERVICE │
│                     │    │                      │    │                     │
│ 1. Request service  │───▶│ 2. Find service      │───▶│ 3. Return interface │
│ 4. Call methods     │◀───┤ 5. Binder IPC        │◀───│ 6. Process requests │
└─────────────────────┘    └──────────────────────┘    └─────────────────────┘
     (priv_app)              (servicemanager)          (hal_brcm_hellowordservice)
```

### Security Boundaries

The HelloWorld service operates with these security boundaries:

1. **Process Isolation**: Runs in dedicated `hal_brcm_hellowordservice` domain
2. **File Access Control**: Limited to vendor partition files
3. **IPC Restrictions**: Only authorized processes can access the service
4. **Capability Limitations**: Minimal system privileges

## File-by-File Analysis

### 1. file_contexts

**File:** `/device/brcm/rpi4/sepolicy/file_contexts`

This file maps file paths to SELinux security contexts.

```plaintext
#Hello_world
/vendor/bin/hw/vendor\.brcm\.helloworld-service  u:object_r:hal_brcm_hellowordservice_exec:s0
```

#### Detailed Breakdown:

**Path Pattern:** `/vendor/bin/hw/vendor\.brcm\.helloworld-service`
- Uses regular expression syntax (note the escaped dots `\.`)
- Matches the HelloWorld service executable in vendor partition
- Located in `/vendor/bin/hw/` (standard HAL service location)

**Security Context:** `u:object_r:hal_brcm_hellowordservice_exec:s0`
- **User (`u`)**: SELinux user, typically 'u' for system processes
- **Role (`object_r`)**: Object role for files and resources
- **Type (`hal_brcm_hellowordservice_exec`)**: Executable type for HelloWorld service
- **Level (`s0`)**: MLS/MCS security level (s0 = unclassified)

#### What This Achieves:
1. **Type Assignment**: Labels the executable with specific type
2. **Domain Transition**: Enables transition to service domain when executed
3. **Access Control**: Other processes need explicit permission to execute this file

### 2. hal_brcm_hellowordservice.te

**File:** `/device/brcm/rpi4/sepolicy/hal_brcm_hellowordservice.te`

This is the main policy file defining permissions for the HelloWorld service.

#### Type Definitions

```selinux
type hal_brcm_hellowordservice, domain, mlstrustedsubject;
type hal_brcm_hellowordservice_exec, exec_type, file_type, vendor_file_type;
type hal_brcm_helloworld_service, service_manager_type;
```

**Analysis:**

**Service Domain Type:**
```selinux
type hal_brcm_hellowordservice, domain, mlstrustedsubject;
```
- **`hal_brcm_hellowordservice`**: Our service's process domain
- **`domain`**: Attribute indicating this type can be used for processes
- **`mlstrustedsubject`**: Multi-level security trusted subject (can access all MLS levels)

**Executable Type:**
```selinux
type hal_brcm_hellowordservice_exec, exec_type, file_type, vendor_file_type;
```
- **`hal_brcm_hellowordservice_exec`**: Type for the service executable
- **`exec_type`**: Can be executed to start processes
- **`file_type`**: Basic file type attribute
- **`vendor_file_type`**: Located in vendor partition

**Service Manager Type:**
```selinux
type hal_brcm_helloworld_service, service_manager_type;
```

**Deep Dive into Service Manager Type:**

**Purpose and Architecture:**
The service manager type is crucial for Android's Inter-Process Communication (IPC) architecture. It represents our service as a discoverable entity within Android's service ecosystem.

**Type Components:**
- **`hal_brcm_helloworld_service`**: Unique identifier for our HelloWorld service in the service registry
- **`service_manager_type`**: Attribute that enables registration with Android's service manager

**Service Manager Architecture Overview:**
```
┌─────────────────────────────────────────────────────────────────┐
│                     ANDROID SERVICE ECOSYSTEM                  │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐  │
│  │   CLIENT APP    │    │ SERVICE MANAGER │    │   HAL SVC   │  │
│  │                 │    │                 │    │             │  │
│  │ 1. getService() │───▶│ 2. lookup()     │───▶│ 3. return   │  │
│  │ 4. remote call  │◀───┤ 5. binder ref   │◀───│    binder   │  │
│  └─────────────────┘    └─────────────────┘    └─────────────┘  │
│       (client_domain)        (servicemanager)   (hal_domain)    │
└─────────────────────────────────────────────────────────────────┘
```

**Service Registration Process:**

**1. Service Startup:**
```cpp
// In HelloWorld service implementation
android::sp<IHelloWorld> service = new HelloWorldImpl();
status_t status = service->registerAsService("default");
```

**2. SELinux Permission Check:**
```selinux
# This rule allows our service to register itself
allow hal_brcm_hellowordservice hal_brcm_helloworld_service:service_manager add;
```

**3. Service Manager Entry:**
```
Service Registry:
┌────────────────────────────────────────────────────────────┐
│ Service Name: vendor.brcm.helloworld.IHelloWorld/default   │
│ Security Context: u:object_r:hal_brcm_helloworld_service:s0│
│ Binder Reference: [IBinder object]                         │
│ PID: [service process ID]                                  │
│ Permissions: [who can access this service]                 │
└────────────────────────────────────────────────────────────┘
```

**Service Discovery Process:**

**1. Client Request:**
```java
// In client application
IHelloWorld service = IHelloWorld.Stub.asInterface(
    ServiceManager.getService("vendor.brcm.helloworld.IHelloWorld/default")
);
```

**2. Permission Verification:**
```selinux
# Client must have permission to find our service
allow priv_app hal_brcm_helloworld_service:service_manager find;
```

**3. Binder Reference Return:**
Service manager returns a binder reference that enables direct communication between client and service.

**Security Implications:**

**Access Control:**
- Only processes with explicit `find` permission can discover our service
- Service registration requires `add` permission
- Each client type must be explicitly authorized

**Isolation Benefits:**
- Service type prevents unauthorized access
- Different services cannot impersonate each other
- Service manager enforces type-based access control

#### Vendor Binder and Daemon Initialization

```selinux
vndbinder_use(hal_brcm_hellowordservice);
init_daemon_domain(hal_brcm_hellowordservice)
```

**Understanding Android's Dual Binder Architecture:**

Android uses two separate binder drivers for enhanced security:

**1. System Binder (`/dev/binder`):**
- Used by system framework services
- Handles system-level IPC
- Higher privilege communications

**2. Vendor Binder (`/dev/vndbinder`):**
- Used by vendor/HAL services
- Isolated from system binder
- Vendor-specific communications

**Vendor Binder Isolation Benefits:**
```
┌─────────────────────┐    ┌─────────────────────┐
│   SYSTEM DOMAIN     │    │   VENDOR DOMAIN     │
│                     │    │                     │
│ ┌─────────────────┐ │    │ ┌─────────────────┐ │
│ │ Framework Apps  │ │    │ │   HAL Services  │ │
│ │    (system)     │ │    │ │   (vendor)      │ │
│ └─────────────────┘ │    │ └─────────────────┘ │
│         │           │    │         │           │
│    /dev/binder      │    │   /dev/vndbinder    │
│         │           │    │         │           │
│ ┌─────────────────┐ │    │ ┌─────────────────┐ │
│ │ servicemanager  │ │    │ │vndservicemanager│ │
│ └─────────────────┘ │    │ └─────────────────┘ │
└─────────────────────┘    └─────────────────────┘
```

**`vndbinder_use()` Macro Detailed Expansion:**

The macro expands to approximately 15-20 rules. Here are the most important ones:

```selinux
# Core vendor binder device access
allow hal_brcm_hellowordservice vndbinder_device:chr_file { open read write ioctl getattr };

# Vendor service manager communication
allow hal_brcm_hellowordservice vndservicemanager:binder { call transfer };
allow hal_brcm_hellowordservice vndservicemanager:service_manager { find add list };

# Vendor binder buffer management
allow hal_brcm_hellowordservice vndbinder_device:chr_file { mmap };

# Death notification handling
allow hal_brcm_hellowordservice vndservicemanager:binder { call };

# Service lifecycle management
allow hal_brcm_hellowordservice self:binder { call transfer set_context_mgr };
```

**What Each Permission Enables:**

**Device Access:**
```selinux
allow hal_brcm_hellowordservice vndbinder_device:chr_file { open read write ioctl };
```
- **`open`**: Access the vendor binder device file
- **`read/write`**: Send/receive binder transactions
- **`ioctl`**: Control binder driver behavior (essential for IPC)

**Service Manager Communication:**
```selinux
allow hal_brcm_hellowordservice vndservicemanager:binder { call transfer };
```
- **`call`**: Make binder calls to vendor service manager
- **`transfer`**: Pass binder references between processes

**Service Registration:**
```selinux
allow hal_brcm_hellowordservice vndservicemanager:service_manager { add list };
```
- **`add`**: Register our service with vendor service manager
- **`list`**: Query available services (for dependencies)

**`init_daemon_domain()` Macro Detailed Expansion:**

This macro enables proper service lifecycle management by init process:

```selinux
# Basic execution permissions
allow init hal_brcm_hellowordservice_exec:file { execute execute_no_trans open read getattr };

# Domain transition for service startup
allow init hal_brcm_hellowordservice:process { transition fork sigchld rlimitinh siginh noatsecure };

# Entry point designation
allow hal_brcm_hellowordservice hal_brcm_hellowordservice_exec:file entrypoint;

# Signal handling for process management
allow init hal_brcm_hellowordservice:process { sigkill sigstop signal };

# File descriptor inheritance
allow hal_brcm_hellowordservice init:fd use;

# Process attribute access for monitoring
allow init hal_brcm_hellowordservice:process { getattr getsched };

# Directory access for service binary
allow init hal_brcm_hellowordservice_exec:file { map };
```

**Service Startup Sequence with SELinux:**

**1. Init Process Preparation:**
```bash
# init.rc service definition triggers startup
service vendor.brcm.helloworld-service /vendor/bin/hw/vendor.brcm.helloworld-service
    class hal
    user nobody
    group nobody
```

**2. SELinux Permission Checks:**
```
init domain checks:
├── Can execute hal_brcm_hellowordservice_exec? ✓
├── Can transition to hal_brcm_hellowordservice? ✓
├── Can fork process? ✓
└── Can set process attributes? ✓
```

**3. Process Creation:**
```
┌─────────────────┐    fork()    ┌─────────────────────────────┐
│   init process  │─────────────▶│  new process (init domain)  │
│  (init domain)  │              │                             │
└─────────────────┘              └─────────────────────────────┘
                                               │
                                      execve() │ + domain transition
                                               ▼
                                 ┌─────────────────────────────┐
                                 │     HelloWorld service      │
                                 │ (hal_brcm_hellowordservice) │
                                 └─────────────────────────────┘
```

**4. Service Registration:**
```cpp
// Service registers with vendor service manager
status_t status = defaultServiceManager()->addService(
    String16("vendor.brcm.helloworld.IHelloWorld/default"),
    service
);
```

**5. SELinux Verification:**
```
Service registration checks:
├── Can access vndbinder device? ✓
├── Can call vendor service manager? ✓
├── Can add service to registry? ✓
└── Service type matches service_contexts? ✓
```

**Debugging Vendor Binder Issues:**

**Check Vendor Binder Device:**
```bash
adb shell ls -la /dev/vndbinder
# Should show: crw-rw-rw- 1 root root 10, 55 ... /dev/vndbinder
```

**Verify Service Registration:**
```bash
adb shell vndservice list | grep helloworld
# Should show: vendor.brcm.helloworld.IHelloWorld/default
```

**Monitor Binder Transactions:**
```bash
adb shell cat /sys/kernel/debug/binder/stats
# Shows vendor binder usage statistics
```

**Common Issues and Solutions:**

**Problem**: Service fails to register
```
Error: Permission denied when calling addService()
```
**Solution**: Check vendor binder permissions
```selinux
# Ensure these rules exist:
allow hal_brcm_hellowordservice hal_brcm_helloworld_service:service_manager add;
allow hal_brcm_hellowordservice vndbinder_device:chr_file rw_file_perms;
```

**Problem**: Client cannot find service
```
Error: Service vendor.brcm.helloworld.IHelloWorld/default not found
```
**Solution**: Check client find permissions
```selinux
# Add client permission:
allow [client_domain] hal_brcm_helloworld_service:service_manager find;
```

This detailed breakdown shows how vendor binder and service manager integration creates a secure, isolated communication channel for our HelloWorld HAL service while maintaining proper Android architectural boundaries.

#### Domain Transition

```selinux
type_transition shell hal_brcm_hellowordservice_exec:process hal_brcm_hellowordservice;
```

**Domain Transition Overview:**

Domain transition is one of the most critical SELinux mechanisms in Android. It controls how processes change their security context when executing new programs. This is essential for maintaining proper isolation between different security domains while allowing legitimate program execution.

**Detailed Breakdown:**

**Rule Components:**
- **Source Domain**: `shell` - The domain of the process initiating execution
- **Target Type**: `hal_brcm_hellowordservice_exec` - The type of the executable file
- **Object Class**: `process` - Indicates this rule applies to process creation
- **Result Domain**: `hal_brcm_hellowordservice` - The domain the new process will run in

**What Happens Step by Step:**

1. **Initial State**: Process running in `shell` domain (typically adb shell session)
2. **Execution Request**: Shell attempts to execute `/vendor/bin/hw/vendor.brcm.helloworld-service`
3. **File Type Check**: System verifies the executable has type `hal_brcm_hellowordservice_exec`
4. **Transition Rule Lookup**: SELinux finds our `type_transition` rule
5. **Domain Switch**: New process automatically gets `hal_brcm_hellowordservice` domain
6. **Policy Enforcement**: New process operates under HelloWorld service policies

**Security Context Changes:**
```
Before execution:
Process: u:r:shell:s0
File:    u:object_r:hal_brcm_hellowordservice_exec:s0

After execution:
Process: u:r:hal_brcm_hellowordservice:s0
```

**Required Supporting Rules:**

For domain transition to work, you need three complementary rules:

1. **Execute Permission** (usually from init):
```selinux
allow init hal_brcm_hellowordservice_exec:file execute;
```

2. **Transition Permission**:
```selinux
allow init hal_brcm_hellowordservice:process transition;
```

3. **Entry Point Permission**:
```selinux
allow hal_brcm_hellowordservice hal_brcm_hellowordservice_exec:file entrypoint;
```

**Alternative Transition Methods:**

Our rule enables **automatic transition**, but SELinux supports other transition types:

**1. Manual Transition** (using `runcon` command):
```bash
# Manual transition (requires additional permissions)
adb shell runcon u:r:hal_brcm_hellowordservice:s0 /vendor/bin/hw/vendor.brcm.helloworld-service
```

**2. Script-based Transition**:
```bash
# Through init.rc script (most common in Android)
service vendor.brcm.helloworld-service /vendor/bin/hw/vendor.brcm.helloworld-service
    class hal
    user nobody
    group nobody
    seclabel u:r:hal_brcm_hellowordservice:s0
```

**Why This Rule Matters:**

**1. Development and Testing:**
```bash
# Enables direct testing from adb shell
adb shell
# Now in shell domain (u:r:shell:s0)

/vendor/bin/hw/vendor.brcm.helloworld-service &
# Process automatically transitions to u:r:hal_brcm_hellowordservice:s0
```

**2. Debugging Capabilities:**
```bash
# Check if service is running with correct domain
adb shell ps -Z | grep helloworld
# Should show: u:r:hal_brcm_hellowordservice:s0

# Test service manually during development
adb shell /vendor/bin/hw/vendor.brcm.helloworld-service
# Service starts with proper security context
```

**3. Security Enforcement:**
Without this rule, the service would either:
- Run in `shell` domain (wrong permissions, security violation)
- Fail to execute (permission denied)
- Require manual context switching (inconvenient for testing)

**Transition Verification:**

**Before Service Execution:**
```bash
adb shell
ps -Z $$  # Shows current shell process
# Output: u:r:shell:s0 ... /system/bin/sh
```

**During Service Execution:**
```bash
adb shell /vendor/bin/hw/vendor.brcm.helloworld-service &
ps -Z | grep helloworld
# Output: u:r:hal_brcm_hellowordservice:s0 ... vendor.brcm.helloworld-service
```

**Security Implications:**

**1. Privilege Escalation Prevention:**
- Service cannot inherit shell's capabilities
- Starts with minimal HelloWorld service permissions
- Cannot access shell's file descriptors or environment

**2. Isolation Guarantee:**
- Service runs in isolated domain regardless of how it's started
- Manual execution from shell has same security as init-started service
- No privilege inheritance from parent process

**3. Attack Surface Reduction:**
- Even if shell is compromised, service maintains its security boundary
- Service cannot be used to escalate privileges back to shell
- Each domain operates under strict access controls

**Common Transition Patterns in Android:**

**1. App Launch:**
```selinux
type_transition zygote app_exec:process untrusted_app;
```

**2. System Service:**
```selinux
type_transition init system_server_exec:process system_server;
```

**3. HAL Service (our case):**
```selinux
type_transition shell hal_brcm_hellowordservice_exec:process hal_brcm_hellowordservice;
```

**Troubleshooting Domain Transitions:**

**Problem**: Service starts but runs in wrong domain
```bash
# Check actual domain
ps -Z | grep helloworld
# If shows u:r:shell:s0 instead of u:r:hal_brcm_hellowordservice:s0
```

**Solution**: Verify transition rule and file labeling
```bash
# Check file context
ls -Z /vendor/bin/hw/vendor.brcm.helloworld-service
# Should show: u:object_r:hal_brcm_hellowordservice_exec:s0

# Re-label if necessary
restorecon /vendor/bin/hw/vendor.brcm.helloworld-service
```

**Process flow with detailed security checks:**
```
1. shell domain (u:r:shell:s0)
   ↓
2. Execute permission check: shell → hal_brcm_hellowordservice_exec:file execute
   ↓
3. File type verification: hal_brcm_hellowordservice_exec
   ↓
4. Transition rule lookup: type_transition shell hal_brcm_hellowordservice_exec:process
   ↓
5. Transition permission check: shell → hal_brcm_hellowordservice:process transition
   ↓
6. Entry point check: hal_brcm_hellowordservice → hal_brcm_hellowordservice_exec:file entrypoint
   ↓
7. New process domain: hal_brcm_hellowordservice (u:r:hal_brcm_hellowordservice:s0)
```

This domain transition mechanism ensures that our HelloWorld service always runs with the correct security context, regardless of how it's invoked, maintaining consistent security boundaries throughout the system.

#### Process and File System Permissions

```selinux
allow hal_brcm_hellowordservice self:process { fork execmem };
allow hal_brcm_hellowordservice vendor_file:file { open read execute };
allow hal_brcm_hellowordservice vendor_file:dir { search open read };
```

**Self Process Permissions:**
```selinux
allow hal_brcm_hellowordservice self:process { fork execmem };
```
- **`fork`**: Can create child processes
- **`execmem`**: Can execute code in memory (needed for some shared libraries)

**Vendor File Access:**
```selinux
allow hal_brcm_hellowordservice vendor_file:file { open read execute };
allow hal_brcm_hellowordservice vendor_file:dir { search open read };
```
- Can access files in vendor partition
- Necessary for loading vendor libraries and configurations

#### Service Manager Communication

```selinux
allow hal_brcm_hellowordservice hal_brcm_helloworld_service:service_manager add;
allow hal_brcm_hellowordservice servicemanager:binder call;
allow hal_brcm_hellowordservice vndbinder_device:chr_file rw_file_perms;
allow hal_brcm_hellowordservice servicemanager:binder transfer;
```

**Service Registration:**
```selinux
allow hal_brcm_hellowordservice hal_brcm_helloworld_service:service_manager add;
```
- Service can register itself with service manager
- Makes service discoverable by clients

**Binder Communication:**
```selinux
allow hal_brcm_hellowordservice servicemanager:binder call;
allow hal_brcm_hellowordservice servicemanager:binder transfer;
```
- Can communicate with service manager via Binder IPC
- Can transfer binder references

**Vendor Binder Device:**
```selinux
allow hal_brcm_hellowordservice vndbinder_device:chr_file rw_file_perms;
```
- Access to vendor binder device (`/dev/vndbinder`)
- Required for vendor service communication

#### Debug and Logging

```selinux
allow hal_brcm_hellowordservice kmsg_device:chr_file write;
```
- Can write to kernel message buffer (`/dev/kmsg`)
- Enables debug logging to kernel log
- Useful for troubleshooting service issues

#### Service Manager Permissions

```selinux
allow servicemanager hal_brcm_hellowordservice:dir search;
allow servicemanager hal_brcm_hellowordservice:file { open read };
allow servicemanager hal_brcm_hellowordservice:process getattr;
allow hal_brcm_hellowordservice servicemanager:service_manager list;
```

**Service Manager Access to Service:**
- Service manager can inspect service directory and files
- Can get process attributes (PID, status, etc.)
- Required for service lifecycle management

**Service Discovery:**
```selinux
allow hal_brcm_hellowordservice servicemanager:service_manager list;
```
- Service can list available services
- May be needed for service dependencies

#### Client Access

```selinux
allow priv_app hal_brcm_helloworld_service:service_manager find;
```
- Privileged applications can find and access the service
- Enables HAL service usage by system and privileged apps

### 3. service_contexts

**File:** `/device/brcm/rpi4/sepolicy/service_contexts`

```plaintext
vendor.brcm.helloworld.IHelloWorld/default  u:object_r:hal_brcm_helloworld_service:s0
```

This file maps service names to security contexts in service manager.

**Service Name:** `vendor.brcm.helloworld.IHelloWorld/default`
- **Interface**: `vendor.brcm.helloworld.IHelloWorld`
- **Instance**: `default`
- Follows HIDL naming convention

**Security Context:** `u:object_r:hal_brcm_helloworld_service:s0`
- Same context as defined in the .te file
- Ensures consistency between policy and service registration

## Policy Rules Explanation

### Rule Types

#### 1. Allow Rules
```selinux
allow source_type target_type:object_class permissions;
```

**Example from our policy:**
```selinux
allow hal_brcm_hellowordservice vendor_file:file { open read execute };
```
- **Source**: `hal_brcm_hellowordservice` (our service)
- **Target**: `vendor_file` (files in vendor partition)
- **Object Class**: `file` (regular files)
- **Permissions**: `open read execute` (specific file operations)

#### 2. Type Transition Rules
```selinux
type_transition source_type target_type:object_class result_type;
```

**Example:**
```selinux
type_transition shell hal_brcm_hellowordservice_exec:process hal_brcm_hellowordservice;
```
- When `shell` executes our service binary, process becomes our service domain

#### 3. Type Definitions
```selinux
type typename [, attribute1, attribute2, ...];
```

**Example:**
```selinux
type hal_brcm_hellowordservice, domain, mlstrustedsubject;
```

### Object Classes and Permissions

#### File Objects
```selinux
file: { create open read write execute ... }
dir: { search open read write add_name remove_name ... }
```

#### Process Objects
```selinux
process: { fork transition sigchld sigkill ... }
```

#### Binder Objects
```selinux
binder: { call transfer ... }
service_manager: { add find list ... }
```

#### Character Device Objects
```selinux
chr_file: { read write open ioctl ... }
```

### Macros

Android SELinux uses macros to simplify common patterns:

#### vndbinder_use(domain)
```selinux
# Expands to:
allow domain vndbinder_device:chr_file rw_file_perms;
allow domain vndservicemanager:binder { call transfer };
# ... and more vendor binder related permissions
```

#### init_daemon_domain(domain)
```selinux
# Expands to:
allow init domain:process { transition fork sigchld };
allow init domain_exec:file execute;
# ... and more init-related permissions
```

## Security Model

### Principle of Least Privilege

Our HelloWorld service follows the principle of least privilege:

1. **Minimal File Access**: Only vendor partition files
2. **Limited Process Capabilities**: Only necessary process operations
3. **Restricted Communication**: Only authorized IPC channels
4. **Controlled Service Access**: Only specific client types can access

### Security Boundaries

#### 1. Process Isolation
```
┌─────────────────────────────────────┐
│        Process Boundary             │
│  ┌─────────────────────────────┐    │
│  │  hal_brcm_hellowordservice  │    │
│  │                             │    │
│  │  - Own memory space         │    │
│  │  - Restricted file access   │    │
│  │  - Limited IPC channels     │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

#### 2. File System Isolation
```
/system/    ← No access (system partition)
/vendor/    ← Limited access (vendor files only)
/data/      ← No access (user data)
/dev/       ← Restricted (only vndbinder, kmsg)
```

#### 3. IPC Isolation
```
System Binder    ← No access
Vendor Binder    ← Full access
Service Manager  ← Limited (registration only)
```

### Attack Surface Reduction

#### What the Policy Prevents:

1. **File System Attacks**:
   - Cannot modify system files
   - Cannot access user data
   - Cannot execute arbitrary binaries

2. **Process Attacks**:
   - Cannot ptrace other processes
   - Cannot change process credentials
   - Cannot access other process memory

3. **Network Attacks**:
   - No network access (no socket permissions)
   - Cannot open network connections
   - Isolated from network services

4. **Device Access**:
   - Cannot access hardware devices directly
   - Limited to specific character devices
   - No access to block devices

## Troubleshooting

### Common SELinux Issues

#### 1. Service Fails to Start

**Symptoms:**
- Service binary exists but doesn't start
- Init reports permission denied

**Check:**
```bash
# Check if executable has correct context
ls -Z /vendor/bin/hw/vendor.brcm.helloworld-service

# Should show: u:object_r:hal_brcm_hellowordservice_exec:s0
```

**Fix:**
```bash
# Re-label the file
restorecon /vendor/bin/hw/vendor.brcm.helloworld-service
```

#### 2. Service Cannot Register

**Symptoms:**
- Service starts but clients cannot find it
- Service manager registration fails

**Check:**
```bash
# List service contexts
adb shell service list | grep helloworld

# Check SELinux denials
adb shell dmesg | grep -i denied | grep helloworld
```

**Common Denial:**
```
denied { add } for service=vendor.brcm.helloworld.IHelloWorld scontext=u:r:hal_brcm_hellowordservice:s0 tcontext=u:object_r:hal_brcm_helloworld_service:s0
```

#### 3. Client Cannot Access Service

**Symptoms:**
- Service is registered but client gets permission denied
- Client apps crash when accessing service

**Check:**
```bash
# Check client domain
adb shell ps -Z | grep [client_process]

# Check if client has find permission
# Look for this rule in policy:
# allow [client_domain] hal_brcm_helloworld_service:service_manager find;
```

#### 4. File Access Denied

**Symptoms:**
- Service cannot load libraries
- Configuration files cannot be read

**Check:**
```bash
# Check file contexts
ls -Z /vendor/lib*/hw/
ls -Z /vendor/etc/

# Look for denials
adb shell dmesg | grep -i denied | grep hal_brcm_hellowordservice
```

### SELinux Debugging Commands

#### Check Current Mode
```bash
adb shell getenforce
# Should return: Enforcing
```

#### Monitor Real-time Denials
```bash
adb shell dmesg -w | grep -i denied
```

#### Check Process Context
```bash
adb shell ps -Z | grep helloworld
```

#### Verify File Contexts
```bash
adb shell ls -Z /vendor/bin/hw/vendor.brcm.helloworld-service
```

#### List Service Contexts
```bash
adb shell service list | grep brcm
```

### Policy Development Tips

#### 1. Start with Permissive Mode
During development, you can temporarily disable enforcement:
```bash
adb shell setenforce 0  # Permissive mode
# Test your service
adb shell setenforce 1  # Back to enforcing
```

#### 2. Collect Denials
Run your service and collect all denials:
```bash
adb shell dmesg | grep -i denied > denials.log
```

#### 3. Generate Allow Rules
Use audit2allow-like tools to generate rules from denials:
```bash
# Example denial:
# denied { read } for path="/vendor/lib/libtest.so" scontext=u:r:hal_brcm_hellowordservice:s0 tcontext=u:object_r:vendor_file:s0

# Generated rule:
allow hal_brcm_hellowordservice vendor_file:file read;
```

#### 4. Test Incrementally
Add permissions gradually and test each addition:
1. Add minimal permissions
2. Test service functionality
3. Add more permissions as needed
4. Always follow principle of least privilege

### Policy Validation

#### Build-time Checks
```bash
# Compile policy
m sepolicy

# Check for neverallow violations
# Build system will report any violations
```

#### Runtime Verification
```bash
# Check if service is properly isolated
adb shell ps -Z | grep hal_brcm_hellowordservice

# Verify service registration
adb shell service list | grep vendor.brcm.helloworld

# Test client access
# (depends on your test client implementation)
```

## Conclusion

This SELinux policy provides a secure foundation for the HelloWorld HAL service by:

1. **Isolating the service** in its own security domain
2. **Limiting file access** to vendor partition only  
3. **Controlling IPC** through vendor binder
4. **Enabling service discovery** for authorized clients
5. **Providing debug capabilities** through kernel messaging

The policy follows Android security best practices and ensures that even if the service is compromised, the impact is limited to the vendor domain without affecting system security.

Remember: **Security is not a feature, it's a foundation**. Every permission granted should be justified and minimal. When in doubt, deny access and add permissions incrementally as needed.
