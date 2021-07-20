package com.sogeti.MLClassification

import android.annotation.SuppressLint
import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.*
import android.util.Size
import android.view.View
import android.widget.TextView
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import org.tensorflow.lite.DataType
import org.tensorflow.lite.Interpreter
import org.tensorflow.lite.support.tensorbuffer.TensorBuffer
import java.lang.Exception
import java.lang.Float.min

class MLService(private val context: Activity): MultiAnalysis.Analyzer, BroadcastReceiver() {

    private var model: Interpreter? = null
    private val predictionView: TextView

    init {
        LocalBroadcastManager.getInstance(context).registerReceiver(this, QRService.updatedModelBroadcastFilter)
        predictionView = context.findViewById(R.id.prediction_view)
        tryLoadModel()
    }


    @SuppressLint("SetTextI18n")
    override fun analyze(image: Bitmap) {
        try {
            val model = model ?: throw NoSuchFileException(Application.modelUrl(context))
            val inputTemplate = model.getInputTensor(0)
            val outputTemplate = model.getOutputTensor(0)

            val output = TensorBuffer.createFixedSize(outputTemplate.shape(), outputTemplate.dataType())
            val input = image
                .rotate(90f)
                .crop(1f)
                .resize(Size(inputTemplate.shape()[1], inputTemplate.shape()[2]))
                .toBuffer(inputTemplate.dataType())

            model.run(input.buffer, output.buffer.rewind())

            val max = output.floatArray.withIndex().maxByOrNull { it.value }!!

            context.runOnUiThread {
                val pred = context.getText(if (max.index == 0) R.string.yes else R.string.no)
                val prob = (max.value * 100).toInt()
                predictionView.visibility = View.VISIBLE
                predictionView.text = "$pred ($prob%)"
            }

        } catch (e: Exception) {
            context.runOnUiThread {
                predictionView.visibility = View.GONE
            }
        }

    }


    private fun tryLoadModel() {
        try {
            model?.close()
            model = Interpreter(Application.modelUrl(context))
        } catch (e: Exception) {
            return
        }
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        tryLoadModel()
    }

    private fun Bitmap.rotate(degrees: Float): Bitmap {
        val matrix = Matrix()
        matrix.postRotate(degrees)
        return Bitmap.createBitmap(this, 0, 0, width, height, matrix, true)
    }

    private fun Bitmap.crop(aspect: Float): Bitmap {
        val w = min(width.toFloat(),height/aspect)
        val h = min(height.toFloat(),width*aspect)
        val x = width*0.5 - w*0.5
        val y = height*0.5 - h*0.5
        return Bitmap.createBitmap(this, x.toInt(), y.toInt(), w.toInt(), h.toInt())
    }

    private fun Bitmap.resize(size: Size): Bitmap {
        val xScale = size.width / width.toFloat()
        val yScale = size.height / height.toFloat()
        val matrix = Matrix()
        matrix.postScale(xScale, yScale)
        return Bitmap.createBitmap(this, 0, 0, width, height, matrix, true)
    }

    private fun Bitmap.toBuffer(dataType: DataType): TensorBuffer {
        val shape = listOf(1, width, height, 3).toIntArray()
        val tensor = TensorBuffer.createFixedSize(shape, dataType)
        for (x in 0 until width) {
            for (y in 0 until height) {
                val pixel = getPixel(x, y)
                tensor.buffer.putFloat(Color.red(pixel) / 255.0f)
                tensor.buffer.putFloat(Color.green(pixel) / 255.0f)
                tensor.buffer.putFloat(Color.blue(pixel) / 255.0f)
            }
        }
        return tensor
    }

}