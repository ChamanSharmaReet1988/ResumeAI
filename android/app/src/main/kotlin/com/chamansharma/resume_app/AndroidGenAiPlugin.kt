package com.quickresume

import com.google.mlkit.genai.common.DownloadStatus
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.prompt.Generation
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class AndroidGenAiPlugin(
    private val scope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate),
) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL_NAME = "resume_app/android_genai"

        fun register(flutterEngine: FlutterEngine) {
            val plugin = AndroidGenAiPlugin()
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
                .setMethodCallHandler(plugin)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> checkAvailable(result)
            "generateText" -> {
                val prompt = call.argument<String>("prompt").orEmpty()
                generateText(prompt, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun checkAvailable(result: MethodChannel.Result) {
        scope.launch {
            try {
                result.success(featureIsUsable())
            } catch (_: Exception) {
                result.success(false)
            }
        }
    }

    private fun generateText(prompt: String, result: MethodChannel.Result) {
        if (prompt.isBlank()) {
            result.error("invalid_prompt", "A prompt is required.", null)
            return
        }

        scope.launch {
            val model = try {
                Generation.getClient()
            } catch (error: Exception) {
                result.error(
                    "android_ai_unavailable",
                    "Gemini Nano is not available on this device.",
                    null,
                )
                return@launch
            }

            try {
                val status = withContext(Dispatchers.IO) { model.checkStatus() }
                when (status) {
                    FeatureStatus.UNAVAILABLE -> {
                        result.error(
                            "android_ai_unavailable",
                            "Gemini Nano is not available on this device.",
                            null,
                        )
                        return@launch
                    }
                    FeatureStatus.DOWNLOADABLE,
                    FeatureStatus.DOWNLOADING,
                    -> {
                        withContext(Dispatchers.IO) {
                            model.download().collect { event ->
                                if (event is DownloadStatus.DownloadFailed) {
                                    throw event.e
                                }
                            }
                        }
                    }
                    else -> Unit
                }

                val response = withContext(Dispatchers.IO) {
                    model.generateContent(prompt)
                }
                val text = response.candidates
                    .map { it.text.trim() }
                    .firstOrNull { it.isNotEmpty() }
                if (text.isNullOrEmpty()) {
                    result.error(
                        "android_ai_empty",
                        "Android on-device AI returned an empty response.",
                        null,
                    )
                } else {
                    result.success(text)
                }
            } catch (error: Exception) {
                val mapped = mapError(error)
                result.error(mapped.first, mapped.second, null)
            } finally {
                model.close()
            }
        }
    }

    private suspend fun featureIsUsable(): Boolean {
        val model = Generation.getClient()
        try {
            val status = withContext(Dispatchers.IO) { model.checkStatus() }
            return status == FeatureStatus.AVAILABLE ||
                status == FeatureStatus.DOWNLOADABLE ||
                status == FeatureStatus.DOWNLOADING
        } finally {
            model.close()
        }
    }

    private fun mapError(error: Exception): Pair<String, String> {
        val text = error.message.orEmpty()
        val lower = text.lowercase()
        return when {
            lower.contains("busy") ->
                "android_ai_busy" to "Android on-device AI is busy right now."
            lower.contains("battery") ->
                "android_ai_busy" to "Android on-device AI is busy right now."
            lower.contains("background") ->
                "android_ai_background" to
                    "Android on-device AI can only run while the app is open."
            lower.contains("unavailable") || lower.contains("not available") ->
                "android_ai_unavailable" to "Gemini Nano is not available on this device."
            lower.contains("download") ->
                "android_ai_assets" to "Android on-device AI is still downloading."
            else ->
                "android_ai_failed" to
                    (text.ifBlank { "Android on-device AI could not finish." })
        }
    }
}
