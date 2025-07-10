#include <android-base/logging.h>
#include <binder/IServiceManager.h>
#include <android/binder_manager.h>
#include <android/binder_process.h>

#include "HelloWorld.h"

using aidl::vendor::brcm::helloworld::HelloWorld;

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
