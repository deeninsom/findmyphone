package com.example.findmyphone

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import android.content.Intent

class MyFirebaseMessagingService : FirebaseMessagingService() {

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d("FCM", "New FCM Token: $token")
        // Kirim token ke server jika diperlukan
        //sendTokenToServer(token)
    }

   override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)

        Log.d("FCM", "Message received from: ${remoteMessage.from}")

        if (remoteMessage.data.isNotEmpty()) {
            val action = remoteMessage.data["action"] ?: "UNKNOWN"
            val deviceId = remoteMessage.data["deviceId"] ?: "N/A"
            val message = remoteMessage.data["message"] ?: "No message"

            Log.d("FCM", "Action: $action, Device ID: $deviceId, Message: $message")

            // Panggil fungsi untuk menangani aksi tertentu
            handleDataTrigger(action, deviceId, message)
        }
    }

    private fun handleDataTrigger(action: String, deviceId: String, message: String) {
        when (action) {
            "WAKE_UP" -> {
                Log.d("FCM", "Triggering wake-up process for device $deviceId")
                // Tambahkan logika untuk menangani WAKE_UP
                startForegroundService()
            }
            "SYNC_DATA" -> {
                Log.d("FCM", "Syncing data for device $deviceId")
                // Tambahkan logika untuk sinkronisasi data
            }
            else -> {
                Log.d("FCM", "Unknown action received: $action")
            }
        }
    }

    private fun startForegroundService() {
        val serviceIntent = Intent(this, ForegroundService::class.java)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent) // Untuk Android 8+ (Oreo)
        } else {
            startService(serviceIntent)
        }
    }
}