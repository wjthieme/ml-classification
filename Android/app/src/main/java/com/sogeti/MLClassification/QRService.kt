package com.sogeti.MLClassification

import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Bitmap
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.ProgressBar
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.google.zxing.*
import com.google.zxing.common.HybridBinarizer
import java.io.*
import java.net.URL

class QRService(private val context: Activity): MultiAnalysis.Analyzer {

    private var isPaused = false
    private val scanner = MultiFormatReader().apply {
        setHints(mapOf(DecodeHintType.POSSIBLE_FORMATS to listOf(BarcodeFormat.QR_CODE)))
    }

    companion object {
        private const val updatedModelBroadcast = "updatedModelBroadcast"
        val updatedModelBroadcastIntent = Intent(updatedModelBroadcast)
        val updatedModelBroadcastFilter = IntentFilter(updatedModelBroadcast)
    }

    override fun analyze(image: Bitmap) {
        try {
            val pixels = IntArray(image.width * image.height)
            image.getPixels(pixels, 0, image.width, 0, 0, image.width, image.height)
            val source = RGBLuminanceSource(image.width, image.height, pixels)
            val binaryBitmap = BinaryBitmap(HybridBinarizer(source))
            val result = scanner.decode(binaryBitmap)
            val uri = Uri.parse(result.text) ?: throw Exception("UnparsableUri")
            didFind(uri)
        } catch (e: Exception) {
            return
        }
    }

    fun didFind(url: Uri) {
        val downloadPath = url.toString().replace("ml-classification://", "")
        if (isPaused) { return }
        val downloadUrl = URL(downloadPath)
        isPaused = true
        startLoading()

        Thread {
            try {
                val connection = downloadUrl.openConnection()
                val inStream = InputStreamReader(connection.getInputStream())
                val reader = BufferedReader(inStream)
                val targetFile = Application.modelUrl(context)
                val writer = FileWriter(targetFile)
                reader.copyTo(writer)
                LocalBroadcastManager.getInstance(context).sendBroadcast(updatedModelBroadcastIntent)
            } catch (e: Exception) {
                didError(e)
            }

            stopLoading()

            Handler(Looper.getMainLooper()).postDelayed({
                isPaused = false
            }, 5000)
        }.start()

    }

    private fun startLoading() {
        if (Looper.myLooper() != Looper.getMainLooper()) { context.runOnUiThread { startLoading() }; return }
        context.findViewById<ProgressBar>(R.id.progress_bar).visibility = View.VISIBLE
    }

    private fun stopLoading() {
        if (Looper.myLooper() != Looper.getMainLooper()) { context.runOnUiThread { stopLoading() }; return }
        context.findViewById<ProgressBar>(R.id.progress_bar).visibility = View.GONE
    }

    private fun didError(error: Exception) {
        if (Looper.myLooper() != Looper.getMainLooper()) { context.runOnUiThread { didError(error) }; return }
        AlertDialog.Builder(context).apply {
            setCancelable(false)
            setTitle(R.string.download_error)
            setMessage(error.localizedMessage)
            setNeutralButton(R.string.ok, null)
        }.create().show()
    }

}


