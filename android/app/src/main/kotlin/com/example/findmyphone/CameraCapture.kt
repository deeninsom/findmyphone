package com.example.findmyphone

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.ImageFormat
import android.hardware.camera2.*
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

    private val CAMERA_PERMISSION_REQUEST_CODE = 101
    private var cameraDevice: CameraDevice? = null
    private var captureSession: CameraCaptureSession? = null
    private var imageReader: ImageReader? = null
    private var cameraId: String? = null
    private lateinit var cameraManager: CameraManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (checkPermissions()) {
            setupCamera()
        } else {
            requestPermissions()
        }
    }

    private fun checkPermissions(): Boolean {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestPermissions() {
        ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.CAMERA), CAMERA_PERMISSION_REQUEST_CODE)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == CAMERA_PERMISSION_REQUEST_CODE) {
            if (grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
                setupCamera()
            } else {
                Toast.makeText(this, "Camera permission denied", Toast.LENGTH_SHORT).show()
                finish()
            }
        }
    }

    private fun setupCamera() {
        cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
        try {
            val frontCameras = cameraManager.cameraIdList.filter { id ->
                cameraManager.getCameraCharacteristics(id)
                    .get(CameraCharacteristics.LENS_FACING) == CameraCharacteristics.LENS_FACING_FRONT
            }

            // Pilih kamera inframerah jika tersedia
            cameraId = frontCameras.firstOrNull { id ->
                val characteristics = cameraManager.getCameraCharacteristics(id)
                isInfraredCamera(characteristics)
            } ?: frontCameras.firstOrNull() // Fallback ke kamera depan biasa jika inframerah tidak ditemukan

            if (cameraId != null) {
                Log.d("CameraCaptureActivity", "Using Camera ID: $cameraId")
                if (ActivityCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
                    getCameraCharacteristics() // Dapatkan karakteristik kamera
                    cameraManager.openCamera(cameraId!!, cameraStateCallback, Handler(Looper.getMainLooper()))
                }
            } else {
                Toast.makeText(this, "Front camera not found", Toast.LENGTH_SHORT).show()
            }
        } catch (e: Exception) {
            Log.e("CameraCaptureActivity", "Error accessing Camera2 API: ${e.message}")
        }
    }

    private fun isInfraredCamera(characteristics: CameraCharacteristics): Boolean {
        val capabilities = characteristics.get(CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES)
        val physicalSize = characteristics.get(CameraCharacteristics.SENSOR_INFO_PHYSICAL_SIZE)
        val isMonochrome = capabilities?.contains(CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES_MONOCHROME) == true

        // Deteksi kamera inframerah berdasarkan fitur monochrome dan ukuran sensor
        return isMonochrome && physicalSize?.width == 1.0f && physicalSize.height == 1.0f
    }

    private fun getCameraCharacteristics() {
        cameraId?.let { id ->
            val characteristics = cameraManager.getCameraCharacteristics(id)

            val exposureRange = characteristics.get(CameraCharacteristics.CONTROL_AE_COMPENSATION_RANGE)
            val isoRange = characteristics.get(CameraCharacteristics.SENSOR_INFO_SENSITIVITY_RANGE)

            exposureRange?.let {
                Log.d("CameraCaptureActivity", "Exposure Range: $it")
            }

            isoRange?.let {
                Log.d("CameraCaptureActivity", "ISO Range: $it")
            }
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
        val characteristics = cameraManager.getCameraCharacteristics(cameraId!!)
        val map = characteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
        val highestResolution = map?.getOutputSizes(ImageFormat.JPEG)?.maxByOrNull { it.width * it.height }

        imageReader = if (highestResolution != null) {
            ImageReader.newInstance(highestResolution.width, highestResolution.height, ImageFormat.JPEG, 1)
        } else {
            ImageReader.newInstance(640, 480, ImageFormat.JPEG, 1)
        }

        imageReader?.setOnImageAvailableListener({ reader ->
            reader.acquireLatestImage()?.let { saveImage(it) }
        }, Handler(Looper.getMainLooper()))

        val surface = imageReader!!.surface
        cameraDevice?.createCaptureSession(
            listOf(surface),
            object : CameraCaptureSession.StateCallback() {
                override fun onConfigured(session: CameraCaptureSession) {
                    captureSession = session
                    captureImageWithCamera2()
                }

                override fun onConfigureFailed(session: CameraCaptureSession) {
                    Toast.makeText(this@CameraCaptureActivity, "Camera session failed", Toast.LENGTH_SHORT).show()
                }
            },
            Handler(Looper.getMainLooper())
        )
    }

    private fun captureImageWithCamera2() {
        try {
            val captureRequestbuilder = cameraDevice?.createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE)?.apply {
                addTarget(imageReader!!.surface)

                set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE)
                set(CaptureRequest.CONTROL_AE_MODE, CaptureRequest.CONTROL_AE_MODE_ON)
                set(CaptureRequest.CONTROL_AWB_MODE, CaptureRequest.CONTROL_AWB_MODE_AUTO)

                val exposureRange = cameraManager.getCameraCharacteristics(cameraId!!).get(
                    CameraCharacteristics.CONTROL_AE_COMPENSATION_RANGE
                )
                val optimalExposure = exposureRange?.upper ?: 0
                set(CaptureRequest.CONTROL_AE_EXPOSURE_COMPENSATION, optimalExposure)

                val isoRange = cameraManager.getCameraCharacteristics(cameraId!!).get(
                    CameraCharacteristics.SENSOR_INFO_SENSITIVITY_RANGE
                )
                val optimalISO = isoRange?.upper ?: 800
                set(CaptureRequest.SENSOR_SENSITIVITY, optimalISO)

            }
            captureSession?.capture(captureRequestbuilder!!.build(), null, null)
        } catch (e: Exception) {
            Log.e("CameraCaptureActivity", "Error capturing image: ${e.message}")
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
                finish()
            }
        }
    }

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

    override fun onDestroy() {
        super.onDestroy()
        cameraDevice?.close()
        cameraDevice = null
    }
}