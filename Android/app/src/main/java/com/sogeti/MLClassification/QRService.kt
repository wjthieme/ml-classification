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
import com.sogeti.MLClassification.Downloader.download
import java.io.*
import java.net.URL

class QRService(private val context: Activity): MultiAnalysis.Analyzer {

    private var isPaused = false
    private val scanner = MultiFormatReader().apply {
        setHints(mapOf(DecodeHintType.POSSIBLE_FORMATS to listOf(BarcodeFormat.QR_CODE)))
    }

    companion object {
        const val endUpdatingModelBroadcast = "endUpdatingModelBroadcast"
        const val startUpdatingModelBroadcast = "startUpdatingModelBroadcast"
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

    fun didFind(uri: Uri) {
        if (isPaused) { return }
        val id = uri.getQueryParameter("id") ?: return
        val hash = uri.getQueryParameter("hash") ?: return

        isPaused = true
        startLoading()
        LocalBroadcastManager.getInstance(context).sendBroadcast(Intent(
            startUpdatingModelBroadcast))

        context.download(id, hash) { error ->
            if (error != null) {
                didError(error)
            }
            LocalBroadcastManager.getInstance(context).sendBroadcast(Intent(
                    endUpdatingModelBroadcast))

            stopLoading()
            Handler(Looper.getMainLooper()).postDelayed({
                isPaused = false
            }, 5000)
        }
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


