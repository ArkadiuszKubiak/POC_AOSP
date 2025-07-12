/**
 * MainActivity is the entry point of the HelloWorld Android application.
 * It sets the content to display the HelloWorldScreen composable.
 *
 * HelloWorldScreen is a composable function that provides a simple UI for sending a message to a native service.
 * 
 * Features:
 * - TextField for user input.
 * - Button to send the input message to a native service asynchronously.
 * - Displays the result of the operation (success or error).
 * - Uses LaunchedEffect and coroutines to handle asynchronous native calls without blocking the UI.
 *
 * State Management:
 * - `text`: Holds the current input from the user.
 * - `result`: Displays the outcome of the native service call.
 * - `isSending`: Indicates whether a message is currently being sent, disabling the button and showing a loading state.
 *
 * Native Integration:
 * - Calls `HelloWorldNative.sayHelloNative(text)` on a background thread using `Dispatchers.IO`.
 * - Updates the UI based on the result of the native call.
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
    // Indicates whether a message is currently being sent.
    var isSending by remember { mutableStateOf(false) }

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
                    // Set isSending to true to trigger the LaunchedEffect and disable the button.
                    isSending = true 
                },
                enabled = !isSending // Disable button while sending to prevent multiple clicks.
            ) {
                // Change button text based on sending state for user feedback.
                Text(if (isSending) "Sending..." else "Send to service")
            }
            // Spacer to add vertical space between elements.
            Spacer(modifier = Modifier.height(16.dp))

            // Display the result message if available.
            result?.let {
                // Show the result of the native call (success or error).
                Text(it)
            }
        }
    }

    // Use LaunchedEffect to call native code asynchronously when isSending changes.
    LaunchedEffect(isSending) {
        if (isSending) {
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
            // Reset sending state to allow further interactions.
            isSending = false
        }
    }
}
