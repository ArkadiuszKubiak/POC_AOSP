/**
 * Singleton object responsible for loading the native library and providing access to native methods.
 *
 * The native library "helloworld_jni" is loaded when this object is initialized.
 */
 
/**
 * Calls the native method to process or display a hello message.
 *
 * @param msg The message to be passed to the native code.
 * @return `true` if the native operation was successful, `false` otherwise.
 */
package com.example.helloworld

object HelloWorldNative {
    init {
        System.loadLibrary("helloworld_jni")
    }

    external fun sayHelloNative(msg: String): Boolean
}