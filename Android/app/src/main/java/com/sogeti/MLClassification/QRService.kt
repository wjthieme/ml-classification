package com.sogeti.MLClassification

import android.app.Activity
import android.app.ProgressDialog
import android.graphics.ImageFormat.*
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import com.google.zxing.*
import com.google.zxing.common.HybridBinarizer
import java.nio.ByteBuffer


class QRService(private val context: Activity): ImageAnalysis.Analyzer {

    private val yuvFormats = listOf(YUV_420_888, YUV_422_888, YUV_444_888)
    private val scanner = MultiFormatReader().apply {
        setHints(mapOf(DecodeHintType.POSSIBLE_FORMATS to listOf(BarcodeFormat.QR_CODE)))
    }
    private val readData: MutableMap<Int, String> = mutableMapOf()

    override fun analyze(proxy: ImageProxy) {
        try {
            if (proxy.format !in yuvFormats) { throw Exception("InvalidFormat") }
            val data = proxy.planes[0].buffer.toByteArray()
            val source = PlanarYUVLuminanceSource(data, proxy.width, proxy.height, 0, 0, proxy.width, proxy.height, false)
            val binaryBitmap = BinaryBitmap(HybridBinarizer(source))
            val result = scanner.decode(binaryBitmap)
            val parts = result.text.split(",")
            if (parts.count() != 3) { throw Exception("InvalidContent") }
            val part = parts[0].toIntOrNull() ?: throw Exception("InvalidContent")
            val total = parts[1].toIntOrNull() ?: throw Exception("InvalidContent")
            readData.put(part, parts[2])
            println("${readData.count()}/${total}")
        } catch (e: Exception) {
            return
        } finally {
            proxy.close()
        }
    }

    private fun ByteBuffer.toByteArray(): ByteArray {
        rewind()
        val data = ByteArray(remaining())
        get(data)
        return data
    }

}


