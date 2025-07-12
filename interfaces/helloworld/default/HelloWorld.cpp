#include "HelloWorld.h"
#include <android-base/logging.h>
#include <fstream>

/**
 * Writes the provided message to the sysfs file "/sys/kernel/hello_world/hello".
 *
 * @param message The string message to be written to the sysfs file.
 * @return ndk::ScopedAStatus indicating success or failure:
 *         - Returns ok() if the message was successfully written.
 *         - Returns fromExceptionCode(EX_ILLEGAL_STATE) if the file could not be opened or the write failed.
 *
 * Logs errors if the file cannot be opened or the write operation fails.
 * Logs info when the message is successfully written.
 */
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