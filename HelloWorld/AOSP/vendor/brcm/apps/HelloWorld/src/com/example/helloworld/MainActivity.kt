/**
 * MainActivity is the entry point of the HelloWorld Android application.
 * It sets the content to display the HelloWorldScreen composable.
 *
 * HelloWorldScreen is a composable function that provides a simple UI for sending a message to a native service.
 * 
 * Features:
 * - TextField for user input.
 * - Button to send the input message to a native service asynchronously via JNI.
 * - Button to send the input message to a vendor service via Binder/ServiceManager.
 * - Displays the result of both operations (success or error).
 * - Uses LaunchedEffect and coroutines to handle asynchronous native calls without blocking the UI.
 *
 * State Management:
 * - `text`: Holds the current input from the user.
 * - `result`: Displays the outcome of the JNI native service call.
 * - `binderResult`: Displays the outcome of the Binder service call.
 * - `isJniCalling`: Indicates whether a JNI call is currently in progress.
 * - `isBinderCalling`: Indicates whether a Binder call is currently in progress.
 *
 * Communication Methods:
 * 1. JNI Integration: Calls `HelloWorldNative.sayHelloNative(text)` on a background thread.
 * 2. Direct AIDL Interface: Uses ServiceManager.getService() and IHelloWorld.Stub.asInterface() for direct method calls.
 *
 * The Direct AIDL implementation:
 * - Gets service from ServiceManager using "vendor.brcm.helloworld.IHelloWorld/default"
 * - Converts raw IBinder to typed interface using IHelloWorld.Stub.asInterface()
 * - Calls service.sayHello(text) directly - no manual marshalling needed!
 * - Much cleaner and type-safe compared to manual transact() calls
 * - Handles errors and displays detailed results
 */
package com.example.helloworld

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import android.os.ServiceManager
import android.os.IBinder
import android.os.Parcel
import vendor.brcm.helloworld.IHelloWorld


// MainActivity is the entry point of the application.
class MainActivity : ComponentActivity() {
    // Called when the activity is first created.
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Set the content of the activity to the HelloWorldScreen composable.
        setContent {
            HelloWorldScreen()
        }
    }
}

// Composable function that displays the main UI for sending a message to a native service.
@Composable
fun HelloWorldScreen() {
    // Holds the current input from the user.
    var text by remember { mutableStateOf("") }
    // Holds the result of the native service call (success or error message).
    var result by remember { mutableStateOf<String?>(null) }
    // Indicates whether a JNI call is currently in progress.
    var isJniCalling by remember { mutableStateOf(false) }
    // Indicates whether Binder call is in progress
    var isBinderCalling by remember { mutableStateOf(false) }
    // Holds the result of Binder operations
    var binderResult by remember { mutableStateOf<String?>(null) }

    /**
     * UI layout using Jetpack Compose that allows the user to input a message, send it to a native service,
     * and display the result. The main functionalities include:
     *
     * 1. **TextField for User Input**: Allows users to enter a message.
     *    - Article: https://developer.android.com/jetpack/compose/text
     *
     * 2. **Button to Send Message**: Initiates sending the message to a native service and shows a loading state.
     *    - Article: https://developer.android.com/jetpack/compose/components/button
     *
     * 3. **Result Display**: Shows the result message after sending.
     *    - Article: https://developer.android.com/jetpack/compose/text#displaying-text
     *
     * 4. **LaunchedEffect for Side Effects**: Handles asynchronous calls to native code when the sending state changes.
     *    - Article: https://developer.android.com/jetpack/compose/side-effects#launchedeffect
     *
     * 5. **Calling Native Code from Kotlin**: Demonstrates invoking native functions using JNI.
     *    - Article: https://developer.android.com/training/articles/perf-jni
     */
    // Layout for the UI elements, centered on the screen.
    Box(
        modifier = Modifier
            // Fill the entire available size of the parent.
            .fillMaxSize()
            // Add padding around the content for better appearance.
            .padding(16.dp),
        // Center the content both vertically and horizontally.
        contentAlignment = androidx.compose.ui.Alignment.Center
    ) {
        // Arrange UI elements vertically in a column, centered horizontally.
        Column(
            horizontalAlignment = androidx.compose.ui.Alignment.CenterHorizontally
        ) {
            // TextField for user input.
            TextField(
                value = text, // Current value of the input field.
                onValueChange = { text = it }, // Update state when user types.
                label = { Text("Enter your message") } // Placeholder label for the field.
            )
            // Spacer to add vertical space between elements.
            Spacer(modifier = Modifier.height(16.dp))

            // Button to send the input message to the native service.
            Button(
                onClick = { 
                    // Set isJniCalling to true to trigger the LaunchedEffect and disable the button.
                    isJniCalling = true 
                },
                enabled = !isJniCalling // Disable button while calling to prevent multiple clicks.
            ) {
                // Change button text based on calling state for user feedback.
                Text(if (isJniCalling) "Calling..." else "Send via JNI")
            }
            
            // Spacer to add vertical space between elements.
            Spacer(modifier = Modifier.height(8.dp))
            
            // Button to send message via direct AIDL interface call
            Button(
                onClick = { 
                    // Set isBinderCalling to true to trigger direct AIDL communication
                    isBinderCalling = true 
                },
                enabled = !isBinderCalling, // Disable button while calling to prevent multiple calls
                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.secondary)
            ) {
                // Change button text based on calling state for user feedback.
                Text(if (isBinderCalling) "Calling..." else "Send via AIDL")
            }
            
            // Spacer to add vertical space between elements.
            Spacer(modifier = Modifier.height(16.dp))

            // Display the result message if available.
            result?.let {
                // Show the result of the native call (success or error).
                Text(
                    text = "JNI Result: $it",
                    color = MaterialTheme.colorScheme.primary
                )
            }
            
            // Display the Binder result if available.
            binderResult?.let {
                // Show the result of the direct AIDL call (success or error).
                Text(
                    text = "AIDL Result: $it",
                    color = MaterialTheme.colorScheme.secondary
                )
            }
        }
    }

    // Use LaunchedEffect to call native code asynchronously when isJniCalling changes.
    LaunchedEffect(isJniCalling) {
        if (isJniCalling) {
            // Call the native function on a background thread.
            val success = withContext(Dispatchers.IO) {
                HelloWorldNative.sayHelloNative(text)
            }
            // Update the result message based on the outcome.
            result = if (success) {
                "Message sent to service!\nSent: $text"
            } else {
                "Error calling the service!\nTried to send: $text"
            }
            // Reset calling state to allow further interactions.
            isJniCalling = false
        }
    }
    
    // Use LaunchedEffect to call service via Binder when isBinderCalling changes.
    LaunchedEffect(isBinderCalling) {
        if (isBinderCalling) {
            // Call the service via Binder on a background thread.
            binderResult = withContext(Dispatchers.IO) {
                try {
                    // Try to get the vendor service from ServiceManager
                    val serviceName = "vendor.brcm.helloworld.IHelloWorld/default"
                    val binder: IBinder? = ServiceManager.getService(serviceName)
                    
                    if (binder == null) {
                        "Service NOT found in ServiceManager!\nSearched for: $serviceName"
                    } else {
                        // Service found, now call sayHello method directly using AIDL stub
                        try {
                            // Convert raw IBinder to typed interface using generated stub
                            val service: IHelloWorld = IHelloWorld.Stub.asInterface(binder)
                            
                            // Note: sayHello returns Unit (void), not String
                            service.sayHello(text)
                            
                            "Direct AIDL call successful!\nService: $serviceName\nSent: '$text'\nMethod: IHelloWorld.sayHello() [Direct]\nNote: Method returns void"
                            
                        } catch (e: Exception) {
                            "Error during direct AIDL call!\nService: $serviceName\nError: ${e.message}\nMessage: '$text'"
                        }
                    }
                } catch (e: Exception) {
                    "Error accessing ServiceManager!\nError: ${e.message}"
                }
            }
            // Reset calling state to allow further interactions.
            isBinderCalling = false
        }
    }
}
