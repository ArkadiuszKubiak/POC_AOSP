package com.example.helloworld

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            HelloWorldScreen()
        }
    }
}

@Composable
fun HelloWorldScreen() {
    var text by remember { mutableStateOf("") }
    var result by remember { mutableStateOf<String?>(null) }

    Column(modifier = Modifier.padding(16.dp)) {
        TextField(
            value = text,
            onValueChange = { text = it },
            label = { Text("Enter your message") }
        )
        Spacer(modifier = Modifier.height(16.dp))
        Button(onClick = {
            val success = HelloWorldNative.sayHelloNative(text)
            result = if (success) "Message sent to service!\nSent: $text" else "Error calling the service!"
        }) {
            Text("Send to service")
        }
        Spacer(modifier = Modifier.height(16.dp))
        result?.let {
            Text(it)
        }
    }
}
