package com.example.findmyphone

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import android.Manifest
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import android.os.Build
import android.app.admin.DevicePolicyManager
import android.content.ComponentName

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.findmyphone/service"
    private val REQUEST_CODE_PERMISSIONS = 1001

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Check for permissions before starting the service
        checkPermissions()

        // Start Foreground Service using MethodChannel
        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startForegroundService" -> {
                    if (hasPermissions()) {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService()
                            result.success("Foreground Service Started")
                        } else {
                            // Start normal service for devices below Android O
                            startService()
                            result.success("Normal Service Started")
                        }
                    } else {
                        result.error("PERMISSION_DENIED", "Permissions are not granted", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

     // Start normal service (for devices below Android O)
    private fun startService() {
        val serviceIntent = Intent(this, ForegroundService::class.java)
        startService(serviceIntent) // Use startService() for lower versions
    }

    // Check if permissions are granted
    private fun hasPermissions(): Boolean {
        val cameraPermission = ContextCompat.checkSelfPermission(this, android.Manifest.permission.CAMERA)
        val storagePermission = ContextCompat.checkSelfPermission(this, android.Manifest.permission.WRITE_EXTERNAL_STORAGE)
        val deviceAdminPermission = isDeviceAdminActive()

        return cameraPermission == PackageManager.PERMISSION_GRANTED && 
               storagePermission == PackageManager.PERMISSION_GRANTED && 
               deviceAdminPermission
    }

    // Periksa apakah perangkat sudah memiliki admin perangkat aktif
    private fun isDeviceAdminActive(): Boolean {
        val devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val componentName = ComponentName(this, MyDevicesAdminReceiver::class.java)

        return devicePolicyManager.isAdminActive(componentName)
    }

    // Request permissions if not granted
    private fun checkPermissions() {
        if (!hasPermissions()) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(android.Manifest.permission.CAMERA, android.Manifest.permission.WRITE_EXTERNAL_STORAGE),
                REQUEST_CODE_PERMISSIONS
            )
        }
    }

    // Start Foreground Service (for devices with Android O and above)
    private fun startForegroundService() {
        val serviceIntent = Intent(this, ForegroundService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent) // Use startForegroundService() on Android O and above
        }
    }

    // Handle the result of the permission request
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_CODE_PERMISSIONS) {
            if (grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
                // Permissions granted, now start the service if required
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService()
                } else {
                    startService()
                }
                Toast.makeText(this, "Permissions granted", Toast.LENGTH_SHORT).show()
            } else {
                Toast.makeText(this, "Permissions denied", Toast.LENGTH_SHORT).show()
            }
        }
    }
}
