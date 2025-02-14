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
import java.io.File
import java.io.FileOutputStream
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Network
import android.net.NetworkRequest
import android.content.BroadcastReceiver
import android.content.IntentFilter
import android.widget.Toast
import io.flutter.plugin.common.MethodChannel
import java.nio.ByteBuffer
import java.text.SimpleDateFormat

class ForegroundService : Service() {

    private val CHANNEL_ID = "findmyphone_service"
    private val NOTIFICATION_ID = 1
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationRequest: LocationRequest
    private lateinit var locationCallback: LocationCallback
    private var eventSink: EventChannel.EventSink? = null
    private var networkCallback: ConnectivityManager.NetworkCallback? = null
    private var networkEventSink: EventChannel.EventSink? = null

    companion object {
        var instance: ForegroundService? = null
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        startForegroundServiceOnce()
        startLocationUpdates()
        registerUsbReceiver()
        registerNetworkCallback()
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

        locationRequest = LocationRequest.create().apply {
            interval = 5000  // Update interval every 5 seconds
            fastestInterval = 2000  // Minimum interval to get a location update every 2 seconds
            priority = LocationRequest.PRIORITY_HIGH_ACCURACY
            smallestDisplacement = 2f  // Get updates when device moves by 2 meters
        }

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                super.onLocationResult(locationResult)

                val location = locationResult.lastLocation
                if (location != null) {
                    Log.d("ForegroundService", "Location Updated: ${location.latitude}, ${location.longitude}")
                    // Send the latest live location to Flutter
                    eventSink?.success(mapOf("latitude" to location.latitude, "longitude" to location.longitude))
                }
            }
        }

        fusedLocationClient.requestLocationUpdates(locationRequest, locationCallback, Looper.getMainLooper())
    }

    fun setEventSink(eventSink: EventChannel.EventSink?) {
        this.eventSink = eventSink
    }
    
    private fun registerUsbReceiver() {
        val filter = IntentFilter(UsbManager.ACTION_USB_DEVICE_ATTACHED)
        registerReceiver(usbReceiver, filter)
    }

    private val usbReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (UsbManager.ACTION_USB_DEVICE_ATTACHED == intent.action) {
                val usbDevice = intent.getParcelableExtra<UsbDevice>(UsbManager.EXTRA_DEVICE)
                usbDevice?.let { handleUsbDevice(it) }
            }
        }
    }

    private fun handleUsbDevice(device: UsbDevice) {
        showToast("USB device detected")
        saveFingerprintData("USB Device Connected: ${device.deviceName} at ${System.currentTimeMillis()}")
        Log.d("ForegroundService", "USB device detected: ${device.deviceName}")
    }

    private fun saveFingerprintData(data: String) {
        val directory = File(getExternalFilesDir(null), "FingerPrints")
        if (!directory.exists()) directory.mkdirs()
        
        // Define the file path for the fingerprint log within the 'FingerPrint' folder
        val file = File(directory, "fingerprint_log.txt")
    
        // Write the data to the file
        FileOutputStream(file, true).use { it.write("$data\n".toByteArray()) }
    }
    

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        // Removing location updates when the service is destroyed
        fusedLocationClient.removeLocationUpdates(locationCallback)

        networkCallback?.let {
            val connectivityManager = getSystemService(ConnectivityManager::class.java)
            connectivityManager.unregisterNetworkCallback(it)
        }
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun showToast(message: String) {
        Handler(Looper.getMainLooper()).post {
            Toast.makeText(this@ForegroundService, message, Toast.LENGTH_SHORT).show()
        }
    }

    private fun registerNetworkCallback() {
    val connectivityManager = getSystemService(ConnectivityManager::class.java)
    val networkRequest = NetworkRequest.Builder().build()

    networkCallback = object : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(network: Network) {
            networkEventSink?.success("Online")
        }

        override fun onLost(network: Network) {
            networkEventSink?.success("Offline")
        }
    }

    connectivityManager.registerNetworkCallback(networkRequest, networkCallback!!)
    }

    fun setNetworkEventSink(eventSink: EventChannel.EventSink?) {
        networkEventSink = eventSink
    }

    fun getCurrentNetworkStatus(): String {
        val connectivityManager = applicationContext.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val activeNetwork = connectivityManager.activeNetwork
        val networkCapabilities = connectivityManager.getNetworkCapabilities(activeNetwork)

        return when {
            networkCapabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true -> "Wi-Fi"
            networkCapabilities?.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) == true -> "Mobile Data"
            else -> "No Network Connection"
        }
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
            SystemClock.elapsedRealtime() + 3000,
            pendingIntent
        )

        super.onTaskRemoved(rootIntent)
    }
    }
