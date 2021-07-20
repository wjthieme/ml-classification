package com.sogeti.MLClassification

import android.content.Context
import com.microsoft.appcenter.AppCenter
import com.microsoft.appcenter.analytics.Analytics
import com.microsoft.appcenter.crashes.Crashes
import com.microsoft.appcenter.distribute.Distribute
import java.io.File

class Application: android.app.Application() {

    companion object {
        private fun homeDir(context: Context) = context.getExternalFilesDir(null)!!
        fun modelUrl(context: Context) = File(homeDir(context), "model.tflite")
    }

    override fun onCreate() {
        super.onCreate()
        AppCenter.start(this, "c910f076-abd7-45b6-bfb6-86b4f0cbdd65", Analytics::class.java, Crashes::class.java,
            Distribute::class.java)

    }

}