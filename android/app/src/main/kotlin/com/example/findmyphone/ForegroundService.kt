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
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbEndpoint
import android.hardware.usb.UsbInterface
import android.hardware.usb.UsbManager
import java.net.HttpURLConnection
import java.net.URL
import java.io.OutputStream
import android.os.AsyncTask
import android.preference.PreferenceManager
import android.provider.Settings

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

        startSendingDataEvery30Minutes()
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
            interval = 5000  
            fastestInterval = 2000  
            priority = LocationRequest.PRIORITY_HIGH_ACCURACY
            smallestDisplacement = 2f  
        }

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                super.onLocationResult(locationResult)

                val location = locationResult.lastLocation
                if (location != null) {
                    Log.d("ForegroundService", "Location Updated: ${location.latitude}, ${location.longitude}")
                    eventSink?.success(mapOf("latitude" to location.latitude, "longitude" to location.longitude))
                }
            }
        }

        fusedLocationClient.requestLocationUpdates(locationRequest, locationCallback, Looper.getMainLooper())
    }

    private val handler = Handler(Looper.getMainLooper())
    private val sendDataRunnable = object : Runnable {
        override fun run() {
            // Ambil lokasi terakhir dari fusedLocationClient dan kirimkan ke API
            fusedLocationClient.lastLocation.addOnSuccessListener { location ->
                if (location != null) {
                    sendDataToApi(location.latitude, location.longitude)
                }
            }
            
            // Menjadwalkan pengiriman data lagi setelah 30 menit (1800000 ms)
            // handler.postDelayed(this, 1800000)
            handler.postDelayed(this, 60000)  // 1 menit = 60000 ms

        }
    }

    private fun startSendingDataEvery30Minutes() {
        // Memulai pengiriman data pertama kali
        sendDataRunnable.run()
    }

    private fun getDeviceId(context: Context): String? {
        return Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID)
    }
    

    private fun sendDataToApi(latitude: Double, longitude: Double) {
        val apiUrl = "http://192.168.60.30:8080/api/v1/location"  // Ganti dengan URL API Anda
    
        val deviceId = getDeviceId(applicationContext)
        Log.d("ForegroundService", "$deviceId")
    if (deviceId.isNullOrEmpty()) {
        Log.e("ForegroundService", "Device ID is missing!")
        return  // Jika deviceId tidak ada, kita tidak melanjutkan pengiriman data
    }
        // Membuat request body dalam format JSON
        val jsonData = """
            {
                "latitude": $latitude,
                "longitude": $longitude,
                "deviceId" : "$deviceId"
            }
        """
    
        // Menggunakan AsyncTask untuk mengirim data secara async
        object : AsyncTask<Void, Void, Void>() {
            override fun doInBackground(vararg params: Void?): Void? {
                try {
                    // Membuka koneksi ke API
                    val url = URL(apiUrl)
                    val connection = url.openConnection() as HttpURLConnection
                    connection.requestMethod = "POST"
                    connection.setRequestProperty("Content-Type", "application/json")
                    connection.doOutput = true
    
                    // Mengirimkan data JSON ke server
                    val outputStream: OutputStream = connection.outputStream
                    outputStream.write(jsonData.toByteArray())
                    outputStream.flush()
                    outputStream.close()
    
                    // Mendapatkan response dari server
                    val responseCode = connection.responseCode
                    Log.d("ForegroundService", "Response Code: $responseCode")
                    connection.disconnect()
                } catch (e: Exception) {
                    Log.e("ForegroundService", "Error sending data to API: ${e.message}")
                }
                return null
            }
        }.execute()
    }

    fun setEventSink(eventSink: EventChannel.EventSink?) {
        this.eventSink = eventSink
    }
    
    private fun registerUsbReceiver() {
        val filter = IntentFilter(UsbManager.ACTION_USB_DEVICE_ATTACHED)
        registerReceiver(usbReceiver, filter)
    }

    // USB Receiver to handle USB device attachment events
    private val usbReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (UsbManager.ACTION_USB_DEVICE_ATTACHED == intent.action) {
                val usbDevice = intent.getParcelableExtra<UsbDevice>(UsbManager.EXTRA_DEVICE)
                usbDevice?.let {
                    handleUsbDevice(it)
                }
            }
        }
    }

    // Handle USB device when connected
    private fun handleUsbDevice(device: UsbDevice) {
        if (isDigitalPersonaDevice(device)) {
            showToast("DigitalPersona USB device detected")
            val connection = openUsbConnection(device)
            connection?.let {
                readDataFromUsbDevice(it)
            }
        } else {
            showToast("Non-DigitalPersona USB device detected")
        }
    }

    private fun isDigitalPersonaDevice(device: UsbDevice): Boolean {
        val vendorId = device.vendorId
        val productId = device.productId
        return vendorId == 1466 && productId == 10 
    }

    // Open a connection to the USB device
    private fun openUsbConnection(device: UsbDevice): UsbDeviceConnection? {
        val usbManager = getSystemService(Context.USB_SERVICE) as UsbManager
        return usbManager.openDevice(device)
    }

    // Read data from USB device
    private fun readDataFromUsbDevice(connection: UsbDeviceConnection) {
        // Assuming that the device uses bulk transfer and you have identified the endpoint
        val endpoint = getEndpointFromDevice()  // Use appropriate endpoint
        val buffer = ByteArray(64)  // Adjust buffer size based on the data you expect
        val length = connection.bulkTransfer(endpoint, buffer, buffer.size, 0)

        if (length > 0) {
            val data = ByteBuffer.wrap(buffer).get()
            Log.d("ForegroundService", "Data received: ${data}")
            saveFingerprintData("Data from device: ${data}")
        } else {
            Log.e("ForegroundService", "Failed to read data from USB device")
        }
    }

    // Get the appropriate endpoint for reading data (this is just an example, adjust as needed)
    private fun getEndpointFromDevice(): UsbEndpoint {
        // Get the UsbManager instance
        val usbManager = getSystemService(Context.USB_SERVICE) as UsbManager
        val usbDevice = usbManager.deviceList.values.firstOrNull()
        usbDevice?.let {
            // Get the first interface from the device
            val usbInterface = it.getInterface(0)
            
            // Get the first endpoint from the interface (adjust as necessary)
            return usbInterface.getEndpoint(0)
        } ?: throw IllegalArgumentException("No valid USB device found")
    }
    
    // Save fingerprint data to a file
    private fun saveFingerprintData(data: String) {
        val directory = File(getExternalFilesDir(null), "FingerPrints")
        if (!directory.exists()) directory.mkdirs()

        val file = File(directory, "fingerprint_log.txt")
        FileOutputStream(file, true).use { it.write("$data\n".toByteArray()) }
    }


    override fun onDestroy() {
        super.onDestroy()
        instance = null
        fusedLocationClient.removeLocationUpdates(locationCallback)

        handler.removeCallbacks(sendDataRunnable)

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
