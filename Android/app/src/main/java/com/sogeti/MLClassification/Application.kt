package com.sogeti.MLClassification

import com.microsoft.appcenter.AppCenter
import com.microsoft.appcenter.analytics.Analytics
import com.microsoft.appcenter.crashes.Crashes
import com.microsoft.appcenter.distribute.Distribute


class Application: android.app.Application() {

    override fun onCreate() {
        super.onCreate()
        AppCenter.start(this, "c910f076-abd7-45b6-bfb6-86b4f0cbdd65", Analytics::class.java, Crashes::class.java,
            Distribute::class.java)

    }

}