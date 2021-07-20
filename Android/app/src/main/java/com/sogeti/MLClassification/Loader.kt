package com.sogeti.MLClassification

import android.annotation.SuppressLint
import android.app.Dialog
import android.content.Context
import android.os.Bundle
import android.widget.Button
import android.widget.ProgressBar
import android.widget.TextView


class Loader(context: Context, private val title: Int, private val cancelAction: () -> Unit): Dialog(context) {

    private lateinit var progressBar: ProgressBar
    private lateinit var titleView: TextView
    private lateinit var messageView: TextView
    private lateinit var cancelButton: Button

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setCancelable(false)
        setContentView(R.layout.loader)

        progressBar = findViewById(R.id.progress_bar)
        titleView = findViewById(R.id.title_label)
        messageView = findViewById(R.id.message_label)
        cancelButton = findViewById(R.id.cancel_button)

        titleView.text = context.getText(title)
        cancelButton.setOnClickListener {
            dismiss()
            cancelAction()
        }
    }


    @SuppressLint("SetTextI18n")
    fun update(progress: Int, max: Int) {
        progressBar.progress = progress
        progressBar.max = max
        val percentage = (progress.toFloat() / max.toFloat() * 100).toInt()
        messageView.text = "$percentage%"
    }
}