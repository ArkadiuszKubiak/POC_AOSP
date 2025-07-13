/**
 * @file service.cpp
 * @brief HelloWorld HAL Service Implementation
 * 
 * This file contains the main entry point for the HelloWorld Hardware Abstraction
 * Layer (HAL) service running on Raspberry Pi 4. The service implements the AIDL interface
 * defined in vendor.brcm.helloworld.IHelloWorld and provides vendor-specific functionality
 * through the Android Binder IPC mechanism.
 * 
 * The service runs as a vendor daemon process and communicates with Android system services
 * and applications through the vndbinder interface, maintaining proper security isolation
 * between vendor and system partitions.
 */

#include <android-base/logging.h>        // Android logging framework
#include <binder/IServiceManager.h>      // Service manager interface
#include <android/binder_manager.h>      // NDK binder service manager APIs
#include <android/binder_process.h>      // NDK binder process management

#include "HelloWorld.h"                  // Local HelloWorld service implementation

// Import the HelloWorld service implementation from the vendor namespace
using aidl::vendor::brcm::helloworld::HelloWorld;

/**
 * @brief Entry point for the HelloWorld HAL service daemon.
 *
 * This function serves as the main entry point for the HelloWorld Hardware
 * Abstraction Layer (HAL) service. It performs the following critical operations:
 * 
 * 1. Process Initialization:
 *    - Configures the binder thread pool for handling concurrent IPC requests
 *    - Sets up logging infrastructure for debugging and monitoring
 * 
 * 2. Service Instance Creation:
 *    - Instantiates the HelloWorld service implementation using NDK shared reference
 *    - Creates a managed object that implements the AIDL interface
 * 
 * 3. Service Registration:
 *    - Registers the service with the Android Service Manager using the exact instance
 *      name specified in the VINTF manifest (vendor.brcm.helloworld.IHelloWorld/default)
 *    - This registration makes the service discoverable by system services and apps
 *    - Uses AServiceManager_addService for vendor service registration via vndbinder
 * 
 * 4. Service Lifecycle Management:
 *    - Joins the binder thread pool to handle incoming IPC requests
 *    - Runs indefinitely until the system terminates the process
 * 
 * Security Context:
 * - Runs in the hal_brcm_hellowordservice SELinux domain
 * - Uses vndbinder for vendor-to-vendor and vendor-to-app communication
 * - Isolated from system partition services for security compliance
 * 
 * Error Handling:
 * - Validates service registration status and logs detailed error information
 * - Returns appropriate exit codes for process monitoring and restart mechanisms
 * 
 * @return int Returns 0 on successful service registration and execution, -1 on failure
 */
int main() {
    // Log service startup for debugging and system monitoring
    LOG(INFO) << "Starting HelloWorld HAL - Vendor service initialization";

    // Configure binder process thread pool for handling concurrent IPC requests
    // Setting max thread count to 0 uses the default system configuration
    // This ensures adequate thread pool sizing for vendor service workloads
    ABinderProcess_setThreadPoolMaxThreadCount(0);

    // Create the HelloWorld service instance using NDK shared reference counting
    // This ensures proper memory management and lifecycle control for the service object
    auto service = ndk::SharedRefBase::make<HelloWorld>();
    
    // Define the exact service instance name as specified in:
    // - VINTF manifest (vendor.brcm.helloworld-manifest.xml)
    // - SELinux service contexts (service_contexts)
    // - Client code expectations
    // Format: <interface_name>/<instance_name>
    const std::string instance = "vendor.brcm.helloworld.IHelloWorld/default";
    LOG(INFO) << "Registering service with instance name: " << instance;

    // Register the service with the Android Service Manager
    // Uses vndbinder for vendor service registration (not system binder)
    // This makes the service discoverable to other processes via Binder IPC
    binder_status_t status = AServiceManager_addService(service->asBinder().get(), instance.c_str());
    if (status != STATUS_OK) {
        LOG(ERROR) << "Failed to register HelloWorld HAL service - Status code: " << status
                   << " (STATUS_OK=" << STATUS_OK << ")";
        LOG(ERROR) << "Possible causes: SELinux denial, service manager unavailable, or duplicate registration";
        return -1;
    }

    LOG(INFO) << "HelloWorld HAL service successfully registered and running";
    LOG(INFO) << "Service is now discoverable at: " << instance;
    
    // Join the binder thread pool to handle incoming IPC requests
    // This call blocks and runs the service until process termination
    // The service will handle method calls from clients in this thread pool
    ABinderProcess_joinThreadPool();
    
    // This return statement should never be reached in normal operation
    return 0;
}
