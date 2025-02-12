package com.example.findmyphone

import android.Manifest
import android.app.*
import android.content.Context
import android.content.Intent
import android.os.*
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*
import io.flutter.plugin.common.EventChannel
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat

class ForegroundService : Service() {

    private val CHANNEL_ID = "findmyphone_service"
    private val NOTIFICATION_ID = 1
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationRequest: LocationRequest
    private lateinit var locationCallback: LocationCallback
    private var eventSink: EventChannel.EventSink? = null

    companion object {
        var instance: ForegroundService? = null
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        startForegroundServiceOnce()
        startLocationUpdates()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    private fun startForegroundServiceOnce() {
        val notificationManager = getSystemService(NotificationManager::class.java)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Foreground Service Channel",
                NotificationManager.IMPORTANCE_LOW
            )
            notificationManager.createNotificationChannel(channel)
        }

        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Security Service Active")
            .setContentText("App active in background...")
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        startForeground(NOTIFICATION_ID, notification)
    }

    private fun startLocationUpdates() {
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)

        locationRequest = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) { 
            // Android 12+ (API 31+)
            LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 5000)
                .setMinUpdateDistanceMeters(2f)
                .build()
        } else {
            // Android 9 hingga Android 11
            LocationRequest.create().apply {
                interval = 5000 // Setiap 5 detik
                fastestInterval = 2000 // Minimal update tiap 2 detik
                priority = LocationRequest.PRIORITY_HIGH_ACCURACY
                smallestDisplacement = 2f // Setiap 2 meter
            }
        }

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                val location = locationResult.lastLocation
                if (location != null) {
                    Log.d("ForegroundService", "Location Updated: ${location.latitude}, ${location.longitude}")
                    eventSink?.success(mapOf("latitude" to location.latitude, "longitude" to location.longitude))
                }
            }
        }

        // Cek izin lokasi sebelum memulai
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
            fusedLocationClient.requestLocationUpdates(locationRequest, locationCallback, Looper.getMainLooper())
        } else {
            Log.e("ForegroundService", "Location permission not granted!")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        fusedLocationClient.removeLocationUpdates(locationCallback)
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    fun setEventSink(eventSink: EventChannel.EventSink?) {
        this.eventSink = eventSink
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        Log.w("ForegroundService", "Service was killed. Restarting in 3 seconds...")

        val restartServiceIntent = Intent(applicationContext, ForegroundService::class.java).apply {
            setPackage(packageName)
        }

        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val pendingIntent = PendingIntent.getService(this, 1, restartServiceIntent, pendingIntentFlags)

        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.setExact(
            AlarmManager.ELAPSED_REALTIME_WAKEUP,
            SystemClock.elapsedRealtime() + 3000, // Restart dalam 3 detik
            pendingIntent
        )

        super.onTaskRemoved(rootIntent)
    }
}
