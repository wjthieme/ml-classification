package com.wjthieme.MLClassification

import android.graphics.*
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executor
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

class MultiAnalysis: ImageAnalysis.Analyzer {

    interface Analyzer {
        fun analyze(image: Bitmap)
    }

    private data class AnalyzerExecutor(
        val analyzer: Analyzer,
        val executor: Executor,
        val isBusy: AtomicBoolean
        )

    override fun analyze(proxy: ImageProxy) {
        val bitmap = proxy.toBitmap()
        for (triple in analyzers) {
            if (triple.isBusy.get())
                continue
            triple.isBusy.set(true)
            triple.executor.execute {
                triple.analyzer.analyze(bitmap)
                triple.isBusy.set(false)
            }
        }
        proxy.close()
    }


    private val analyzers: MutableList<AnalyzerExecutor> = mutableListOf()

    fun addAnalyzer(analyzer: Analyzer) {
        val analyzerExecutor = AnalyzerExecutor(analyzer, Executors.newSingleThreadExecutor(), AtomicBoolean(false))
        analyzers.add(analyzerExecutor)
    }

    fun build(block: (ImageAnalysis.Builder) -> ImageAnalysis.Builder): ImageAnalysis {
        return block(ImageAnalysis.Builder()).build().also {
            it.setAnalyzer(Executors.newSingleThreadExecutor(), this)
        }
    }

    private fun ImageProxy.toBitmap(): Bitmap {
        val yBuffer = planes[0].buffer // Y
        val uBuffer = planes[1].buffer // U
        val vBuffer = planes[2].buffer // V

        val ySize = yBuffer.remaining()
        val uSize = uBuffer.remaining()
        val vSize = vBuffer.remaining()

        val nv21 = ByteArray(ySize + uSize + vSize)

        yBuffer.get(nv21, 0, ySize)
        vBuffer.get(nv21, ySize, vSize)
        uBuffer.get(nv21, ySize + vSize, uSize)

        val yuvImage = YuvImage(nv21, ImageFormat.NV21, this.width, this.height, null)
        val out = ByteArrayOutputStream()
        yuvImage.compressToJpeg(Rect(0, 0, yuvImage.width, yuvImage.height), 50, out)
        val imageBytes = out.toByteArray()
        return BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
    }

}