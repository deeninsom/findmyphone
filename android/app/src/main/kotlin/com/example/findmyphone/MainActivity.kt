package com.example.findmyphone

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.os.BatteryManager
import android.os.Environment
import android.os.StatFs
import android.telephony.TelephonyManager


import android.os.Bundle

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.findmyphone/service"
    private val LOCATION_CHANNEL = "com.example.findmyphone/location"
    private val DEVICE_CHANNEL = "com.example.findmyphone/device" 
    private val REQUEST_CODE = 1001
    private var pendingResult: MethodChannel.Result? = null
    private var requestedPermission: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("MainActivity", "onCreate() called. Foreground service running ...")
        startForegroundServiceIfNeeded()
    }

    private fun startForegroundServiceIfNeeded() {
        val serviceIntent = Intent(this, ForegroundService::class.java)
        Log.d("MainActivity", "Attempting to start foreground service...")

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
            Log.d("MainActivity", "Foreground service started with startForegroundService()")
        } else {
            startService(serviceIntent)
            Log.d("MainActivity", "Foreground service started with startService()")
        }
    }

    private fun isForegroundServiceRunning(): Boolean {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
        for (service in activityManager.getRunningServices(Integer.MAX_VALUE)) {
            if (ForegroundService::class.java.name == service.service.className) {
                return true
            }
        }
        return false
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // MethodChannel untuk menangani izin dan service
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermissions" -> {
                    val missingPermissions = getMissingPermissions()
                    Log.d("MainActivity", "Missing Permissions: $missingPermissions")
                    result.success(missingPermissions)
                }
                "requestPermission" -> {
                    val permission = call.argument<String>("permission") ?: return@setMethodCallHandler
                    Log.d("MainActivity", "Requesting permission: $permission")
                    requestPermission(permission, result)
                }
                "requestBatteryOptimization" -> {
                    requestIgnoreBatteryOptimization(result)
                }
                "isIgnoringBatteryOptimizations" -> {
                    result.success(isIgnoringBatteryOptimizations())
                }
                else -> result.notImplemented()
            }
        }
        

        // EventChannel untuk mengirim live location ke Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    ForegroundService.instance?.setEventSink(events)
                }
        
                override fun onCancel(arguments: Any?) {
                    ForegroundService.instance?.setEventSink(null)
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeviceInfo" -> {
                    val deviceInfo = getDeviceInfo()
                    result.success(deviceInfo)
                }
                else -> result.notImplemented()
            }
        }
        
    }

    private fun getMissingPermissions(): List<String> {
        val permissions = mapOf(
            "camera" to Manifest.permission.CAMERA,
            "location" to Manifest.permission.ACCESS_FINE_LOCATION,
            "storage" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
                Manifest.permission.READ_MEDIA_IMAGES
            else
                Manifest.permission.READ_EXTERNAL_STORAGE
        )

        val missingPermissions = permissions.filter { (_, androidPermission) ->
            ContextCompat.checkSelfPermission(this, androidPermission) != PackageManager.PERMISSION_GRANTED
        }.keys.toMutableList()

        if (!isIgnoringBatteryOptimizations()) {
            Log.d("MainActivity", "Battery optimization is enabled. Adding to missing permissions.")
            missingPermissions.add("battery")
        }

        Log.d("MainActivity", "Checked missing permissions: $missingPermissions")
        return missingPermissions
    }

    private fun requestPermission(permission: String, result: MethodChannel.Result) {
        if (permission == "battery") {
            requestIgnoreBatteryOptimization(result)
            return
        }

        val androidPermission = when (permission) {
            "camera" -> Manifest.permission.CAMERA
            "location" -> Manifest.permission.ACCESS_FINE_LOCATION
            "storage" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
                Manifest.permission.READ_MEDIA_IMAGES
            else
                Manifest.permission.READ_EXTERNAL_STORAGE
            else -> null
        }

        if (androidPermission == null) {
            Log.e("MainActivity", "Invalid permission type: $permission")
            result.error("INVALID_PERMISSION", "Permission type is invalid", null)
            return
        }

        if (ContextCompat.checkSelfPermission(this, androidPermission) == PackageManager.PERMISSION_GRANTED) {
            Log.d("MainActivity", "Permission $permission already granted")
            result.success(true)
            return
        }

        pendingResult = result
        requestedPermission = permission
        ActivityCompat.requestPermissions(this, arrayOf(androidPermission), REQUEST_CODE)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            Log.d("MainActivity", "Permission ${requestedPermission ?: "unknown"} granted: $granted")
            pendingResult?.success(granted)
            pendingResult = null
            requestedPermission = null
        }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            powerManager.isIgnoringBatteryOptimizations(packageName)
        } else {
            true
        }
    }

    private fun requestIgnoreBatteryOptimization(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                Log.d("MainActivity", "Requesting battery optimization exception.")
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = Uri.parse("package:$packageName")
                }
                startActivity(intent)
                Log.d("MainActivity", "Battery optimization request sent.")
                result.success(true)
            } catch (e: Exception) {
                Log.e("MainActivity", "Error requesting battery optimization", e)
                result.error("ERROR", "Failed to request battery optimization", null)
            }
        } else {
            Log.d("MainActivity", "Battery optimization not needed for Android < 6.0")
            result.success(true)
        }
    }

    // New method to fetch device information
    // Remove the getStorageInfo() and getImei() methods

private fun getDeviceInfo(): Map<String, Any> {
    val deviceInfo = mutableMapOf<String, Any>()
    
    // Model and Manufacturer
    deviceInfo["model"] = Build.MODEL
    deviceInfo["manufacturer"] = Build.MANUFACTURER
    
    // Battery level
    val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
    val batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
    deviceInfo["batteryLevel"] = batteryLevel
    
    // Chipset (CPU Architecture)
    val cpuArch = Build.SUPPORTED_ABIS[0]
    deviceInfo["cpuArchitecture"] = cpuArch
    
    // Wi-Fi Status
    val wifiStatus = getWifiStatus()
    deviceInfo["wifiStatus"] = wifiStatus

    return deviceInfo
}

// Method to fetch Wi-Fi status
private fun getWifiStatus(): String {
    val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as android.net.wifi.WifiManager
    val connectionInfo = wifiManager.connectionInfo

    return if (connectionInfo.networkId == -1) {
        "No Wi-Fi Connection"
    } else {
        val ssid = connectionInfo.ssid.replace("\"", "")
        "$ssid"
    }
}

    
}
