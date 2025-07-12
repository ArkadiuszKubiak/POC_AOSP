// hello_world_jni.cpp

#include <jni.h>
#include <android/binder_manager.h>
#include <aidl/vendor/brcm/helloworld/IHelloWorld.h>
#include <iostream>

using aidl::vendor::brcm::helloworld::IHelloWorld;

extern "C"
/**
 * Native implementation of HelloWorld's sayHello method.
 *
 * This JNI function is called from Java to send a hello message to the
 * vendor.brcm.helloworld.IHelloWorld service via AIDL. It retrieves the
 * service binder, casts it to the IHelloWorld interface, and invokes
 * the sayHello method with the provided message string.
 *
 * @param env   Pointer to the JNI environment.
 * @param thiz  Reference to the calling Java object (unused).
 * @param jmsg  Java string containing the message to send.
 * @return JNI_TRUE if the message was sent successfully, JNI_FALSE otherwise.
 */
JNIEXPORT jboolean JNICALL
Java_com_example_helloworld_HelloWorldNative_sayHelloNative(JNIEnv* env, jobject /* thiz */, jstring jmsg) {
    std::cout << "[JNI] sayHelloNative called" << std::endl;
    // Check if the service is declared in the service manager.
    std::cout << "[JNI] Checking if service is declared..." << std::endl;
    if (!AServiceManager_isDeclared("vendor.brcm.helloworld.IHelloWorld/default")) {
        std::cout << "Service not declared!" << std::endl;
        return -1;
    }
    // Convert the Java string (jmsg) to a C-style UTF-8 string.
    const char* c_msg = env->GetStringUTFChars(jmsg, nullptr);
    if (!c_msg) {
        std::cout << "[JNI] Failed to convert jstring to UTF-8" << std::endl;
        return JNI_FALSE;
    }
    std::cout << "[JNI] Converted jstring to UTF-8: " << c_msg << std::endl;

    // Get the binder for the IHelloWorld service from the Android service manager.
    std::cout << "[JNI] Attempting to get service binder..." << std::endl;
    ndk::SpAIBinder binder(
            AServiceManager_getService("vendor.brcm.helloworld.IHelloWorld/default"));

    // Check if the service binder was found.
    if (!binder.get()) {
        std::cout << "[JNI] Service not found!" << std::endl;
        env->ReleaseStringUTFChars(jmsg, c_msg);
        return JNI_FALSE;
    }
    std::cout << "[JNI] Service binder obtained successfully" << std::endl;

    // Cast the binder to the IHelloWorld AIDL interface.
    std::cout << "[JNI] Casting binder to IHelloWorld interface..." << std::endl;
    std::shared_ptr<IHelloWorld> service = IHelloWorld::fromBinder(binder);

    // Check if the cast was successful.
    if (service == nullptr) {
        std::cout << "[JNI] Failed to cast binder to IHelloWorld" << std::endl;
        env->ReleaseStringUTFChars(jmsg, c_msg);
        return JNI_FALSE;
    }
    std::cout << "[JNI] Successfully cast binder to IHelloWorld" << std::endl;

    // Call the sayHello method on the IHelloWorld service with the message.
    std::cout << "[JNI] Calling sayHello on service with message: " << c_msg << std::endl;
    ndk::ScopedAStatus status = service->sayHello(c_msg);

    // Release the UTF-8 string resources.
    env->ReleaseStringUTFChars(jmsg, c_msg);
    std::cout << "[JNI] Released UTF-8 string resources" << std::endl;

    // Check if the sayHello call was successful.
    if (!status.isOk()) {
        std::cout << "[JNI] Failed to call sayHello(): "
                  << status.getDescription() << std::endl;
        return JNI_FALSE;
    }

    std::cout << "[JNI] sayHello call succeeded" << std::endl;
    // Return JNI_TRUE to indicate success.
    return JNI_TRUE;
}