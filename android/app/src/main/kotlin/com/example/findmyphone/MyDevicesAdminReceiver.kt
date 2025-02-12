package com.example.findmyphone

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.Toast
import android.content.SharedPreferences
import android.os.UserHandle

class MyDevicesAdminReceiver : DeviceAdminReceiver() {
    private val TAG = "MyDevicesAdminReceiver"
    private val PREFS_NAME = "com.example.findmyphone.PREFS"
    private val FAILED_ATTEMPT_KEY = "failed_attempts"

    private fun showToast(context: Context, msg: String) {
        Toast.makeText(context, msg, Toast.LENGTH_SHORT).show()
    }

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Log.i(TAG, "Device Admin Enabled")
        showToast(context, "Device Admin Enabled")
    }

    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        return "onDisableRequested"
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Log.i(TAG, "Device Admin Disabled")
        showToast(context, "Device Admin Disabled")
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

    private fun handleFailedAttempts(context: Context) {
        val sharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        var failedAttempts = sharedPreferences.getInt(FAILED_ATTEMPT_KEY, 0)

        failedAttempts++

        sharedPreferences.edit().putInt(FAILED_ATTEMPT_KEY, failedAttempts).apply()

        if (failedAttempts == 2) {
            takePhoto(context)
            sharedPreferences.edit().putInt(FAILED_ATTEMPT_KEY, 0).apply()
        }
    }

    private fun takePhoto(context: Context) {
        val intent = Intent(context, CameraCaptureActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(intent)
    }
}