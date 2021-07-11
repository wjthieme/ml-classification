package com.sogeti.MLClassification

import android.annotation.SuppressLint
import android.os.SystemClock
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import com.google.android.gms.tasks.Task
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import kotlin.math.min

class MultiAnalysis: ImageAnalysis.Analyzer {

    @SuppressLint("UnsafeOptInUsageError")
    override fun analyze(proxy: ImageProxy) {
        val start = SystemClock.uptimeMillis()
        for (analyzer in analyzers) {
             analyzer.analyze(proxy)
        }
        proxy.close()
    }

    private val analyzers: MutableList<ImageAnalysis.Analyzer> = mutableListOf()

    fun addAnalyzer(analysis: ImageAnalysis.Analyzer) {
        analyzers.add(analysis)
    }

    fun build(block: (ImageAnalysis.Builder) -> ImageAnalysis.Builder): ImageAnalysis {
        return block(ImageAnalysis.Builder()).build().also {
            it.setAnalyzer(Executors.newSingleThreadExecutor(), this)
        }
    }

}