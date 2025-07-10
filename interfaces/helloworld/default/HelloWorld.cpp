#include "HelloWorld.h"
#include <android-base/logging.h>
#include <fstream>

namespace aidl::vendor::brcm::helloworld {

ndk::ScopedAStatus HelloWorld::sayHello(const std::string& message) {
    std::ofstream file("/sys/kernel/hello_world/hello");
    if (!file.is_open()) {
        LOG(ERROR) << "Cannot open sysfs file for writing";
        return ndk::ScopedAStatus::fromExceptionCode(EX_ILLEGAL_STATE);
    }

    file << message;
    if (!file) {
        LOG(ERROR) << "Failed to write message to sysfs";
        return ndk::ScopedAStatus::fromExceptionCode(EX_ILLEGAL_STATE);
    }

    file.close();
    LOG(INFO) << "Wrote to sysfs: " << message;
    return ndk::ScopedAStatus::ok();
}

}