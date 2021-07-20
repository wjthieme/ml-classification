package com.sogeti.MLClassification

import android.R.attr.bitmap
import android.app.Activity
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Bitmap
import android.graphics.ImageFormat.*
import android.os.Handler
import android.os.Looper
import android.util.Base64
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.google.zxing.*
import com.google.zxing.common.HybridBinarizer
import java.nio.ByteBuffer


class QRService(private val context: Activity): MultiAnalysis.Analyzer {

    private var loader: Loader? = null
    private var isPaused = false
    private val scanner = MultiFormatReader().apply {
        setHints(mapOf(DecodeHintType.POSSIBLE_FORMATS to listOf(BarcodeFormat.QR_CODE)))
    }
    private var readData: MutableMap<Int, String> = mutableMapOf()

    companion object {
        val updatedModelBroadcast = "updatedModelBroadcast"
        val updatedModelBroadcastIntent = Intent(updatedModelBroadcast)
        val updatedModelBroadcastFilter = IntentFilter(updatedModelBroadcast)
    }

    override fun analyze(image: Bitmap) {
        if (isPaused) { return }
        try {
            val pixels = IntArray(image.width * image.height)
            image.getPixels(pixels, 0, image.width, 0, 0, image.width, image.height)
            val source = RGBLuminanceSource(image.width, image.height, pixels)
            val binaryBitmap = BinaryBitmap(HybridBinarizer(source))
            val result = scanner.decode(binaryBitmap)
            val parts = result.text.split(",")
            if (parts.count() != 3) { throw Exception("InvalidContent") }
            val part = parts[0].toIntOrNull() ?: throw Exception("InvalidContent")
            val total = parts[1].toIntOrNull() ?: throw Exception("InvalidContent")

            if (loader == null) {
                isPaused = true
                readData = mutableMapOf()
                context.runOnUiThread {
                    loader = Loader(context, R.string.scanning) {
                        loader = null
                    }
                    loader?.show()
                    isPaused = false
                }
            }

            readData[part] = parts[2]
            context.runOnUiThread {
                loader?.update(readData.count(), total)
            }

            if (readData.count() == total) {
                isPaused = true
                val base64 = readData.toSortedMap().values.joinToString()
                val modelData = Base64.decode(base64, Base64.DEFAULT)
                Application.modelUrl(context).writeBytes(modelData)

                LocalBroadcastManager.getInstance(context).sendBroadcast(updatedModelBroadcastIntent)

                context.runOnUiThread {
                    loader?.dismiss()
                    loader = null
                }

                Handler(Looper.getMainLooper()).postDelayed({
                    isPaused = false
                }, 5000)
            }

        } catch (e: Exception) {
            return
        }
    }

    private fun ByteBuffer.toByteArray(): ByteArray {
        rewind()
        val data = ByteArray(remaining())
        get(data)
        return data
    }

}


