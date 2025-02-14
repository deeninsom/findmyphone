package com.example.findmyphone

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.hardware.Camera
import android.os.*
import android.util.Log
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.*

class CameraCaptureActivity : Activity() {

    private val CAMERA_PERMISSION_REQUEST_CODE = 101
    private var camera: Camera? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Jangan set layout apapun karena tidak ada UI yang perlu ditampilkan

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
        try {
            // Menggunakan kamera depan (Camera API yang lama)
            val cameraCount = Camera.getNumberOfCameras()
            var frontCameraId: Int? = null

            for (i in 0 until cameraCount) {
                val info = Camera.CameraInfo()
                Camera.getCameraInfo(i, info)
                if (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
                    frontCameraId = i
                    break
                }
            }

            if (frontCameraId != null) {
                camera = Camera.open(frontCameraId)
                val parameters = camera?.parameters
                parameters?.setFocusMode(Camera.Parameters.FOCUS_MODE_AUTO) // Fokus otomatis
                camera?.parameters = parameters

                // Mulai preview kamera (walaupun tidak akan ditampilkan di UI)
                camera?.startPreview()

                // Ambil gambar langsung setelah setup selesai
                takePictureInBackground()

            } else {
                Toast.makeText(this, "Front camera not found", Toast.LENGTH_SHORT).show()
            }

        } catch (e: Exception) {
            Log.e("CameraCaptureActivity", "Error accessing Camera: ${e.message}")
        }
    }

    // Menangkap gambar dan menyimpannya ke penyimpanan
    private fun takePictureInBackground() {
        // Menjalankan pengambilan gambar di thread background agar tidak mengganggu UI
        Thread {
            try {
                camera?.takePicture(null, null, Camera.PictureCallback { data, _ ->
                    saveImage(data)
                })
            } catch (e: Exception) {
                Log.e("CameraCaptureActivity", "Error capturing image: ${e.message}")
            }
        }.start()
    }

    private fun saveImage(imageData: ByteArray) {
        val savedFile = saveImageToStorage(imageData)
        runOnUiThread {
            savedFile?.let {
                // Menampilkan pesan Toast hanya untuk konfirmasi, jika diperlukan
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
        camera?.release() // Lepaskan kamera saat activity dihancurkan
        camera = null
    }
}






// package com.example.findmyphone

// import android.Manifest
// import android.app.Activity
// import android.content.pm.PackageManager
// import android.hardware.Camera
// import android.os.*
// import android.util.Log
// import android.widget.Toast
// import androidx.core.app.ActivityCompat
// import androidx.core.content.ContextCompat
// import java.io.File
// import java.io.FileOutputStream
// import java.text.SimpleDateFormat
// import java.util.*

// class CameraCaptureActivity : Activity() {

//     private val CAMERA_PERMISSION_REQUEST_CODE = 101
//     private var camera: Camera? = null

//     override fun onCreate(savedInstanceState: Bundle?) {
//         super.onCreate(savedInstanceState)
//         if (checkPermissions()) {
//             setupCamera()
//         } else {
//             requestPermissions()
//         }
//     }

//     private fun checkPermissions(): Boolean {
//         return ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
//     }

//     private fun requestPermissions() {
//         ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.CAMERA), CAMERA_PERMISSION_REQUEST_CODE)
//     }

//     override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
//         super.onRequestPermissionsResult(requestCode, permissions, grantResults)
//         if (requestCode == CAMERA_PERMISSION_REQUEST_CODE) {
//             if (grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
//                 setupCamera()
//             } else {
//                 Toast.makeText(this, "Camera permission denied", Toast.LENGTH_SHORT).show()
//                 finish()
//             }
//         }
//     }

//     private fun setupCamera() {
//         try {
//             // Menggunakan kamera depan (Camera API yang lama)
//             val cameraCount = Camera.getNumberOfCameras()
//             var frontCameraId: Int? = null

//             for (i in 0 until cameraCount) {
//                 val info = Camera.CameraInfo()
//                 Camera.getCameraInfo(i, info)
//                 if (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
//                     frontCameraId = i
//                     break
//                 }
//             }

//             if (frontCameraId != null) {
//                 camera = Camera.open(frontCameraId)
//                 val parameters = camera?.parameters
//                 parameters?.setFocusMode(Camera.Parameters.FOCUS_MODE_AUTO) // Fokus otomatis
//                 camera?.parameters = parameters

//                 // Mulai preview kamera (bisa menambahkan SurfaceView atau TextureView)
//                 camera?.setPreviewDisplay(null)
//                 camera?.startPreview()

//                 // Langsung ambil gambar setelah setup selesai
//                 takePictureInBackground()

//             } else {
//                 Toast.makeText(this, "Front camera not found", Toast.LENGTH_SHORT).show()
//             }

//         } catch (e: Exception) {
//             Log.e("CameraCaptureActivity", "Error accessing Camera: ${e.message}")
//         }
//     }

//     // Menangkap gambar dan menyimpannya ke penyimpanan
//     private fun takePictureInBackground() {
//         // Menjalankan pengambilan gambar di thread background agar tidak mengganggu UI
//         Thread {
//             try {
//                 camera?.takePicture(null, null, Camera.PictureCallback { data, _ ->
//                     saveImage(data)
//                 })
//             } catch (e: Exception) {
//                 Log.e("CameraCaptureActivity", "Error capturing image: ${e.message}")
//             }
//         }.start()
//     }

//     private fun saveImage(imageData: ByteArray) {
//         val savedFile = saveImageToStorage(imageData)
//         runOnUiThread {
//             savedFile?.let {
//                 Toast.makeText(this@CameraCaptureActivity, "Image saved at: ${it.absolutePath}", Toast.LENGTH_SHORT).show()
//                 finish()
//             }
//         }
//     }

//     private fun saveImageToStorage(imageData: ByteArray): File? {
//         val directory = File(getExternalFilesDir(null), "CapturedImages")
//         if (!directory.exists()) directory.mkdirs()

//         val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
//         val imageFile = File(directory, "IMG_${timeStamp}.jpg")

//         return try {
//             FileOutputStream(imageFile).use { it.write(imageData) }
//             imageFile
//         } catch (e: Exception) {
//             Log.e("CameraCaptureActivity", "Error saving image: ${e.message}")
//             null
//         }
//     }

//     override fun onDestroy() {
//         super.onDestroy()
//         camera?.release() // Lepaskan kamera saat activity dihancurkan
//         camera = null
//     }
// }
