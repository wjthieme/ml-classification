package com.wjthieme.MLClassification

import android.content.Context
import com.wjthieme.MLClassification.Application.Companion.modelUrl
import java.net.URL
import java.security.MessageDigest

object Downloader {

    fun Context.download(id: String, hash: String, completion: (Exception?) -> Unit) {
        val url = if (id == "test") Application.testModel else Application.baseUrl.append(id)
        Thread {
            try {
                val connection = url.openConnection()
                val inputStream = connection.getInputStream()
                val data = inputStream.readBytes()
                if (sha1(data) != hash) throw SecurityException()
                modelUrl().writeBytes(data)
                inputStream.close()
                completion(null)
            } catch (e: Exception) {
                completion(e)
            }
        }.start()
    }

    private fun URL.append(pathComponent: String): URL {
        return URL(protocol, host, port, "$path/$pathComponent?$query", null)
    }

    private fun sha1(data: ByteArray): String {
        val hasher = MessageDigest.getInstance("SHA-1")
        val digest = hasher.digest(data)
        return digest.joinToString("") { String.format("%02x", it) }
    }

}