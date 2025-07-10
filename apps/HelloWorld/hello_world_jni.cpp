// hello_world_jni.cpp

#include <jni.h>
#include <android/binder_manager.h>
#include <aidl/vendor/brcm/helloworld/IHelloWorld.h>
#include <iostream>

using aidl::vendor::brcm::helloworld::IHelloWorld;

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_example_helloworld_HelloWorldNative_sayHelloNative(JNIEnv* env, jobject /* thiz */, jstring jmsg) {
    const char* c_msg = env->GetStringUTFChars(jmsg, nullptr);

    ndk::SpAIBinder binder(
            AServiceManager_getService("vendor.brcm.helloworld.IHelloWorld/default"));

    if (!binder.get()) {
        std::cout << "Service not found!" << std::endl;
        env->ReleaseStringUTFChars(jmsg, c_msg);
        return JNI_FALSE;
    }

    std::shared_ptr<IHelloWorld> service = IHelloWorld::fromBinder(binder);

    if (service == nullptr) {
        std::cout << "Failed to cast binder to IHelloWorld" << std::endl;
        env->ReleaseStringUTFChars(jmsg, c_msg);
        return JNI_FALSE;
    }

    ndk::ScopedAStatus status = service->sayHello(c_msg);

    env->ReleaseStringUTFChars(jmsg, c_msg);

    if (!status.isOk()) {
        std::cout << "Failed to call sayHello(): "
                  << status.getDescription() << std::endl;
        return JNI_FALSE;
    }

    return JNI_TRUE;
}