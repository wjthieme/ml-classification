package com.sogeti.MLClassification

import android.app.AlertDialog
import android.content.Context

class Loader(context: Context, title: String, cancelAction: () -> Unit): AlertDialog(context) {

    init {
        setTitle(title)
        setMessage("0%")
        setCancelable(false)
        setButton(BUTTON_NEUTRAL, context.getText(R.string.cancel)) { _, _ -> cancelAction() }
    }


    fun update(progress: Float) {

    }

    fun update(title: String) {

    }
}