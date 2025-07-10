package com.example.helloworld

object HelloWorldNative {
    init {
        System.loadLibrary("helloworld_jni")
    }

    external fun sayHelloNative(msg: String): Boolean
}