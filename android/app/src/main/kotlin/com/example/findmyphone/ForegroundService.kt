package com.example.findmyphone

import android.Manifest
import android.app.*
import android.content.Context
import android.content.Intent
import android.os.*
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*
import android.location.Location
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
        // Ensuring the service is sticky so that it restarts if it gets killed
        return START_STICKY
    }

    private fun startForegroundServiceOnce() {
        val notificationManager = getSystemService(NotificationManager::class.java)

        // Creating the notification channel if needed (for Android O and above)
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

        // Setting up the LocationRequest
        locationRequest = LocationRequest.create().apply {
            interval = 5000 // Update interval every 5 seconds
            fastestInterval = 2000 // Minimum interval to get a location update every 2 seconds
            priority = LocationRequest.PRIORITY_HIGH_ACCURACY
            smallestDisplacement = 2f // Get updates when device moves by 2 meters
        }

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                super.onLocationResult(locationResult)

                val location = locationResult.lastLocation
                if (location != null) {
                    Log.d("ForegroundService", "Location Updated: ${location.latitude}, ${location.longitude}")
                    // Ensure eventSink is not null before sending data
                    eventSink?.success(mapOf("latitude" to location.latitude, "longitude" to location.longitude))
                }
            }
        }

        // Checking if the location permission is granted before requesting updates
        // Checking if the location permission is granted before requesting updates
    if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
        fusedLocationClient.requestLocationUpdates(locationRequest, locationCallback, Looper.getMainLooper())

        // Request the last known location immediately when the service starts
        fusedLocationClient.lastLocation.addOnSuccessListener { location: Location? ->
            if (location != null) {
                Log.d("ForegroundService", "Last known location: ${location.latitude}, ${location.longitude}")
                // Send the last known location if available
                eventSink?.success(mapOf("latitude" to location.latitude, "longitude" to location.longitude))
            }
        }
    } else {
        Log.e("ForegroundService", "Location permission not granted!")
    }
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        // Removing location updates when the service is destroyed
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

        // Checking if the service is already running before attempting to restart
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
            SystemClock.elapsedRealtime() + 3000, // Restart the service after 3 seconds
            pendingIntent
        )

        super.onTaskRemoved(rootIntent)
    }
}
