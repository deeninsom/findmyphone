package com.example.findmyphone

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.ImageFormat
import android.hardware.Camera
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraDevice
import android.hardware.camera2.CameraCaptureSession
import android.hardware.camera2.CameraManager
import android.media.Image
import android.media.ImageReader
import android.os.*
import android.util.Log
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.Executors


class CameraCaptureActivity : Activity() {

    private val CAMERA_AND_STORAGE_PERMISSION_REQUEST_CODE = 124
    private var camera: Camera? = null
    private var cameraDevice: CameraDevice? = null
    private var captureSession: CameraCaptureSession? = null
    private var imageReader: ImageReader? = null
    private var cameraId: String? = null

    private val executor = Executors.newSingleThreadExecutor()
    private lateinit var cameraManager: CameraManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (checkPermissions()) {
            captureImage()
        } else {
            requestPermissions()
        }
    }

    private fun checkPermissions(): Boolean {
        val permissions = arrayOf(
            Manifest.permission.CAMERA,
            Manifest.permission.WRITE_EXTERNAL_STORAGE
        )
        return permissions.all {
            ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestPermissions() {
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.CAMERA, Manifest.permission.WRITE_EXTERNAL_STORAGE),
            CAMERA_AND_STORAGE_PERMISSION_REQUEST_CODE
        )
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == CAMERA_AND_STORAGE_PERMISSION_REQUEST_CODE) {
            if (grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
                captureImage()
            } else {
                Toast.makeText(this, "Camera permission denied", Toast.LENGTH_SHORT).show()
                finish()
            }
        }
    }

    private fun captureImage() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            Toast.makeText(this, "Using Camera2 API", Toast.LENGTH_SHORT).show()
            captureUsingCamera2() // Capture image in background
        } else {
            Toast.makeText(this, "Using Legacy Camera API", Toast.LENGTH_SHORT).show()
            captureUsingLegacyCamera() // Capture image in background
        }
    }

    // ===================== CAMERA2 API (Android 5.0+) ===================== //
    private fun captureUsingCamera2() {
    cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
    try {
        // Log all available cameras
        cameraManager.cameraIdList.forEach { id ->
            val characteristics = cameraManager.getCameraCharacteristics(id)
            val lensFacing = characteristics.get(CameraCharacteristics.LENS_FACING)
            val cameraName = if (lensFacing == CameraCharacteristics.LENS_FACING_FRONT) "Front" else "Back"
            Log.d("CameraCaptureActivity", "Camera ID: $id - $cameraName")
        }

        // Select the front-facing camera as the default
        cameraId = cameraManager.cameraIdList.firstOrNull { id ->
            cameraManager.getCameraCharacteristics(id)
                .get(CameraCharacteristics.LENS_FACING) == CameraCharacteristics.LENS_FACING_FRONT
        }

Log.d("CameraCaptureActivity", "tidak temu")
        // If a front camera is found, open it
        if (cameraId != null) {
            Log.d("CameraCaptureActivity", "Using Camera ID: $cameraId for front camera.")
            cameraManager.openCamera(cameraId!!, cameraStateCallback, Handler(Looper.getMainLooper()))
        } else {
            Toast.makeText(this, "Front camera not found", Toast.LENGTH_SHORT).show()
        }

    } catch (e: Exception) {
        Log.e("CameraCaptureActivity", "Error accessing Camera2 API: ${e.message}")
    }
}


    private val cameraStateCallback = object : CameraDevice.StateCallback() {
        override fun onOpened(camera: CameraDevice) {
            cameraDevice = camera
            startCameraCaptureSession()
        }

        override fun onDisconnected(camera: CameraDevice) {
            camera.close()
            cameraDevice = null
        }

        override fun onError(camera: CameraDevice, error: Int) {
            camera.close()
            cameraDevice = null
            Log.e("CameraCaptureActivity", "Camera error: $error")
        }
    }

    private fun startCameraCaptureSession() {
        imageReader = ImageReader.newInstance(640, 480, ImageFormat.JPEG, 1)
        imageReader?.setOnImageAvailableListener({ reader ->
            reader.acquireLatestImage()?.let { saveImage(it) }
        }, null)

        val targets = listOf(imageReader?.surface)
        cameraDevice?.createCaptureSession(targets, object : CameraCaptureSession.StateCallback() {
            override fun onConfigured(session: CameraCaptureSession) {
                captureSession = session
                captureImageWithCamera2()
            }

            override fun onConfigureFailed(session: CameraCaptureSession) {
                Toast.makeText(this@CameraCaptureActivity, "Camera session failed", Toast.LENGTH_SHORT).show()
            }
        }, null)
    }

    private fun captureImageWithCamera2() {
        cameraDevice?.createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE)?.apply {
            addTarget(imageReader!!.surface)
            captureSession?.capture(build(), null, null)
        }
    }

    private fun saveImage(image: Image) {
        val buffer: ByteBuffer = image.planes[0].buffer
        val bytes = ByteArray(buffer.remaining())
        buffer.get(bytes)
        image.close()

        val savedFile = saveImageToStorage(bytes)
        runOnUiThread {
            savedFile?.let {
                Toast.makeText(this@CameraCaptureActivity, "Image saved at: ${it.absolutePath}", Toast.LENGTH_SHORT).show()
            }
        }
    }

    // ===================== LEGACY CAMERA API (Android 4.4) ===================== //
    private fun captureUsingLegacyCamera() {
        executor.execute {
            try {
                val cameraId = findFrontCameraId()
                if (cameraId == -1) {
                    runOnUiThread {
                        Toast.makeText(this, "Front camera not found", Toast.LENGTH_SHORT).show()
                    }
                    return@execute
                }

                camera = Camera.open(cameraId)
                camera?.apply {
                    setPreviewCallback { _, _ ->
                        // No preview callback needed, it's for background capture
                    }
                    takePicture(null, null, Camera.PictureCallback { data, _ ->
                        saveImageToStorage(data)
                    })
                }
            } catch (e: Exception) {
                Log.e("CameraCaptureActivity", "Error opening camera: ${e.message}")
                releaseCamera()
            }
        }
    }

    private fun findFrontCameraId(): Int {
        val numberOfCameras = Camera.getNumberOfCameras()
        for (i in 0 until numberOfCameras) {
            val info = Camera.CameraInfo()
            Camera.getCameraInfo(i, info)
            if (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
                return i
            }
        }
        return -1
    }

    // ===================== IMAGE STORAGE ===================== //
    private fun saveImageToStorage(imageData: ByteArray): File? {
        val directory = File(getExternalFilesDir(null), "CapturedImages")
        if (!directory.exists()) directory.mkdirs()

        val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
        val imageFile = File(directory, "IMG_${timeStamp}.jpg")

        return try {
            FileOutputStream(imageFile).use { it.write(imageData) }
            imageFile
        } catch (e: Exception) {
            Log.e("CameraCaptureActivity", "Error saving image: ${e.message}")
            null
        }
    }

    private fun releaseCamera() {
        camera?.release()
        camera = null
    }
}
