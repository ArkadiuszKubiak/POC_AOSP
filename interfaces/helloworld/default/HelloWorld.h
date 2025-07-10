#pragma once

#include <aidl/vendor/brcm/helloworld/BnHelloWorld.h>

namespace aidl::vendor::brcm::helloworld {

class HelloWorld : public BnHelloWorld {
public:
    ndk::ScopedAStatus sayHello(const std::string& message) override;
};

}
