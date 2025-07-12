#include <android-base/logging.h>
#include <binder/IServiceManager.h>
#include <android/binder_manager.h>
#include <android/binder_process.h>

#include "HelloWorld.h"

using aidl::vendor::brcm::helloworld::HelloWorld;

/**
 * @brief Entry point for the HelloWorld HAL service.
 *
 * This function initializes and registers the HelloWorld HAL service with the Android
 * service manager. It logs the startup process, creates the service instance, and
 * registers it under the descriptor "HelloWorld/default".
 *
 * The registration is performed using AServiceManager_addService, which adds the service
 * to the Android Binder service manager. This function takes the binder interface pointer
 * and the instance name as arguments. If the service is successfully registered, it becomes
 * discoverable and accessible to other processes via Binder IPC. If registration fails,
 * the function logs an error and exits with a non-zero status.
 *
 * Upon successful registration, the service joins the binder thread pool to handle incoming
 * IPC requests.
 *
 * @return int Returns 0 on successful service registration and execution, -1 otherwise.
 */
int main() {
    LOG(INFO) << "Starting HelloWorld HAL";

    auto service = ndk::SharedRefBase::make<HelloWorld>();
    const std::string instance = std::string() + HelloWorld::descriptor + "/default";
    LOG(INFO) << "Registering service: " << instance;

    binder_status_t status = AServiceManager_addService(service->asBinder().get(), instance.c_str());
    if (status != STATUS_OK) {
        LOG(ERROR) << "Could not register service";
        return -1;
    }

    LOG(INFO) << "HelloWorld HAL is running";
    ABinderProcess_joinThreadPool();
    return 0;
}
