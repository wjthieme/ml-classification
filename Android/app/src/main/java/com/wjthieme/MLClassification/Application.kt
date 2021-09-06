package com.wjthieme.MLClassification

import android.content.Context
import com.microsoft.appcenter.AppCenter
import com.microsoft.appcenter.analytics.Analytics
import com.microsoft.appcenter.crashes.Crashes
import com.microsoft.appcenter.distribute.Distribute
import java.io.File
import java.net.URL

class Application: android.app.Application() {

    companion object {
        private fun Context.homeDir() = getExternalFilesDir(null)!!
        fun Context.modelUrl() = File(homeDir(), "model.tflite")
        const val appCenterClientId = "c910f076-abd7-45b6-bfb6-86b4f0cbdd65"
        val baseUrl = URL("https://a.tmp.ninja/")
        val testModel = URL("https://github.com/wjthieme/ml-classification/blob/main/model.tflite?raw=true")
    }

    override fun onCreate() {
        super.onCreate()
        AppCenter.start(this, appCenterClientId, Analytics::class.java, Crashes::class.java,
            Distribute::class.java)

    }

}