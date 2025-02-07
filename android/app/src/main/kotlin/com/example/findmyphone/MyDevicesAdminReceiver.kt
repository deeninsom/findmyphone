package com.example.findmyphone

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.UserHandle
import android.util.Log
import android.widget.Toast
import android.app.admin.DevicePolicyManager
import android.content.ComponentName


class MyDevicesAdminReceiver : DeviceAdminReceiver() {

    private val TAG = "MyDevicesAdminReceiver"
    private val PREFS_NAME = "com.example.findmyphone.PREFS"
    private val FAILED_ATTEMPT_KEY = "failed_attempts"

    private fun showToast(context: Context, msg: String) {
        Toast.makeText(context, msg, Toast.LENGTH_SHORT).show()
    }

    // Increment failed attempts and trigger photo capture on 2nd failure
    private fun handleFailedAttempts(context: Context) {
        val sharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        var failedAttempts = sharedPreferences.getInt(FAILED_ATTEMPT_KEY, 0)

        failedAttempts++

        // Update failed attempts count
        sharedPreferences.edit().putInt(FAILED_ATTEMPT_KEY, failedAttempts).apply()

        if (failedAttempts == 2) {
            // Take photo using the front camera after 2 failed attempts
            takePhoto(context)
            // Reset the failed attempts counter
            sharedPreferences.edit().putInt(FAILED_ATTEMPT_KEY, 0).apply()
        }
    }

    private fun takePhoto(context: Context) {
        // Start an Activity or Service to capture a photo
        val intent = Intent(context, CameraCaptureActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(intent)
    }

    // Check if the device admin is enabled and show toast
    private fun checkDeviceAdminStatus(context: Context) {
    val devicePolicyManager = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
    val componentName = ComponentName(context, MyDevicesAdminReceiver::class.java)

    // Log whether the device admin is active or not
    val isAdminActive = devicePolicyManager.isAdminActive(componentName)
    Log.i(TAG, "Device Admin Active: $isAdminActive")

    if (!isAdminActive) {
        // Show a toast asking the user to enable device admin
        showToast(context, "Please enable Device Admin to use this feature.")
        
        // Log that we're prompting the user to enable device admin
        Log.i(TAG, "Prompting user to enable Device Admin.")

        // Optionally, prompt the user to enable it
        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componentName)
        intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "Enable device admin for security features.")

        // Log that we are starting the activity to enable Device Admin
        Log.i(TAG, "Starting activity to enable Device Admin.")
        
        context.startActivity(intent)
    } else {
        Log.i(TAG, "Device Admin is already enabled.")
    }
}


    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Log.i(TAG, "onEnabled")
        showToast(context, "Device Admin Enabled")
    }

    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        return "onDisableRequested"
    }

    override fun onDisabled(context: Context, intent: Intent) {
          super.onDisabled(context, intent)
        Log.i(TAG, "onDisabled")
        showToast(context, "Device Admin Disabled")
    }

    override fun onPasswordChanged(context: Context, intent: Intent, userHandle: UserHandle) {
        showToast(context, "Password Changed")
    }

    override fun onPasswordFailed(context: Context, intent: Intent, userHandle: UserHandle) {
        Log.i(TAG, "onPasswordFailed")
        showToast(context, "Password Failed")
        handleFailedAttempts(context)  // Handle failed attempts
    }

    override fun onPasswordSucceeded(context: Context, intent: Intent, userHandle: UserHandle) {
        Log.i(TAG, "onPasswordSucceeded")
        showToast(context, "Password Succeeded")
    }

    // Call this method in your main activity or somewhere appropriate
    fun enableDeviceAdminIfNeeded(context: Context) {
        checkDeviceAdminStatus(context)
    }
}
