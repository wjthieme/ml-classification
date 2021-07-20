package com.sogeti.MLClassification

import android.Manifest
import android.app.AlertDialog
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import android.util.Size
import android.view.WindowManager
import android.widget.ImageButton
import androidx.appcompat.app.AppCompatActivity
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat

class Activity: AppCompatActivity() {

    private val permissions = arrayOf(Manifest.permission.CAMERA)
    private val permissionsRequestCode = 12741

    private lateinit var cameraView: PreviewView
    private lateinit var switchButton: ImageButton
    private var cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setBackgroundDrawable(null)
        window.setFlags(
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
        );
        setContentView(R.layout.activity_main)

        cameraView = findViewById(R.id.camera_view)
        switchButton = findViewById(R.id.switch_button)
        switchButton.setOnClickListener {
            if (cameraSelector == CameraSelector.DEFAULT_BACK_CAMERA) {
                cameraSelector = CameraSelector.DEFAULT_FRONT_CAMERA
                switchButton.setImageResource(R.drawable.ic_camera_rear)
            } else {
                cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA
                switchButton.setImageResource(R.drawable.ic_camera_front)
            }
            shouldStartCamera()
        }
    }

    override fun onStart() {
        super.onStart()
        shouldStartCamera()
    }

    private fun shouldStartCamera() {
        when (allPermissionsGranted()) {
            true -> startCamera()
            false -> requestPermissions(permissions, permissionsRequestCode)
        }
    }

    private fun startCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(this)

        cameraProviderFuture.addListener(Runnable {
            val cameraProvider: ProcessCameraProvider = cameraProviderFuture.get()

            val analysis = MultiAnalysis().also {
                it.addAnalyzer(QRService(this@Activity))
                it.addAnalyzer(MLService(this@Activity))
            }.build {
                it.setTargetResolution(Size(cameraView.width, cameraView.height))
                it.setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            }

            val preview = Preview.Builder()
                .build()
                .apply {
                    setSurfaceProvider(cameraView.surfaceProvider)
                }

            try {
                cameraProvider.unbindAll()
                cameraProvider.bindToLifecycle(this, cameraSelector, preview, analysis)

            } catch(e: Exception) {
                return@Runnable
            }

        }, ContextCompat.getMainExecutor(this))
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        if (requestCode == permissionsRequestCode) {
            if (allPermissionsGranted()) {
                startCamera()
            } else {
               AlertDialog.Builder(this).apply {
                    setCancelable(false)
                    setMessage(R.string.camera_authorization)
                    setNeutralButton(R.string.settings) { _, _ ->
                        val intent = Intent()
                        intent.action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                        intent.data = Uri.fromParts("package", packageName, null)
                        startActivity(intent)
                    }
               }.create().show()
            }
        } else {
            super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        }
    }

    private fun allPermissionsGranted() = permissions.all {
        checkSelfPermission(it) == PackageManager.PERMISSION_GRANTED
    }



}