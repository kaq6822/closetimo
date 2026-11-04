// 005 — Android 기기 내 사진 분석 채널(`closetimo/vision`). iOS와 같은 메서드를 제공한다.
// Dart 쪽: lib/core/vision/native_vision.dart
//
// - 배경 제거: ML Kit Subject Segmentation(Play 서비스 모듈, beta)
// - 분류 라벨: ML Kit Image Labeling(Play 서비스 모듈). 종류·소재 힌트는 Dart가 판정한다.
// - 기기 내 AI: Gemini Nano Prompt API(AICore 지원 기기, API 26+). 허용 값 목록은 Dart가 넘긴다.
// 사진은 기기 밖으로 보내지 않는다. 단, ML Kit은 기능 진단 정보(기기 모델·성능 지표 등)를
// Google에 보낸다(사용자 승인, 헌법 III 예외 2026-11-02). 로그는 영문으로 남긴다.

package com.closetimo.app

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.os.Build
import android.util.Log
import androidx.exifinterface.media.ExifInterface
import com.google.android.gms.common.moduleinstall.ModuleInstall
import com.google.android.gms.common.moduleinstall.ModuleInstallRequest
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.prompt.Generation
import com.google.mlkit.genai.prompt.GenerativeModel
import com.google.mlkit.genai.prompt.ImagePart
import com.google.mlkit.genai.prompt.TextPart
import com.google.mlkit.genai.prompt.generateContentRequest
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.label.ImageLabeling
import com.google.mlkit.vision.label.defaults.ImageLabelerOptions
import com.google.mlkit.vision.segmentation.subject.SubjectSegmentation
import com.google.mlkit.vision.segmentation.subject.SubjectSegmenterOptions
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.UUID
import kotlin.math.max
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import org.json.JSONArray
import org.json.JSONObject

class ClosetimoVisionChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, CHANNEL)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private val segmenter by lazy {
        SubjectSegmentation.getClient(
            SubjectSegmenterOptions.Builder().enableForegroundBitmap().build(),
        )
    }
    private val labeler by lazy {
        ImageLabeling.getClient(
            ImageLabelerOptions.Builder().setConfidenceThreshold(LABEL_MIN_CONFIDENCE).build(),
        )
    }

    /** Gemini Nano 클라이언트. API 26 미만에서는 만들지 않는다(라이브러리 minSdk 26). */
    private val model: GenerativeModel? by lazy {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) Generation.getClient() else null
    }

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        scope.cancel()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "capabilities" -> scope.launch {
                result.success(
                    mapOf(
                        "backgroundRemoval" to true,
                        "classification" to true,
                        "onDeviceAi" to aiStatus(),
                    ),
                )
            }
            "analyze" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("bad_args", "path is required", null)
                    return
                }
                val removeBackground = call.argument<Boolean>("removeBackground") ?: false
                scope.launch { result.success(analyze(path, removeBackground)) }
            }
            "describe" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("bad_args", "path is required", null)
                    return
                }
                @Suppress("UNCHECKED_CAST")
                val schema = call.argument<Map<String, List<String>>>("schema") ?: emptyMap()
                scope.launch {
                    try {
                        result.success(describe(path, schema))
                    } catch (e: UnsupportedOperationException) {
                        result.error("unsupported", e.message, null)
                    } catch (e: Exception) {
                        Log.w(TAG, "On-device AI failed: $e")
                        result.error("failed", e.message, null)
                    }
                }
            }
            "prewarm" -> scope.launch {
                prewarm()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    // ── 기능 확인 ──

    private suspend fun aiStatus(): String {
        val model = model ?: return "unsupported"
        return try {
            when (model.checkStatus()) {
                FeatureStatus.AVAILABLE -> "available"
                FeatureStatus.DOWNLOADABLE, FeatureStatus.DOWNLOADING -> "notReady"
                else -> "unsupported"
            }
        } catch (e: Exception) {
            Log.w(TAG, "Gemini Nano status check failed: $e")
            "unsupported"
        }
    }

    /** 분석 모델을 미리 준비한다. Play 서비스 모듈은 설치를 요청하고, Gemini Nano는 내려받거나 깨운다. */
    private suspend fun prewarm() {
        requestModules()
        val model = model ?: return
        try {
            when (model.checkStatus()) {
                FeatureStatus.DOWNLOADABLE -> scope.launch {
                    try {
                        model.download().collect { }
                    } catch (e: Exception) {
                        Log.w(TAG, "Gemini Nano download failed: $e")
                    }
                }
                FeatureStatus.AVAILABLE -> model.warmup()
                else -> Unit
            }
        } catch (e: Exception) {
            Log.w(TAG, "Gemini Nano prewarm failed: $e")
        }
    }

    /** 배경 제거·라벨 모듈이 없으면 설치를 요청한다(완료를 기다리지 않는다). */
    private suspend fun requestModules(): Boolean {
        val client = ModuleInstall.getClient(context)
        return try {
            val available = client.areModulesAvailable(segmenter, labeler).await().areModulesAvailable()
            if (!available) {
                client.installModules(
                    ModuleInstallRequest.newBuilder().addApi(segmenter).addApi(labeler).build(),
                )
            }
            available
        } catch (e: Exception) {
            Log.w(TAG, "ML Kit module check failed: $e")
            false
        }
    }

    // ── 배경 제거 + 분류 ──

    private suspend fun analyze(path: String, removeBackground: Boolean): Map<String, Any> {
        val output = mutableMapOf<String, Any>("labels" to emptyList<Any>())
        val bitmap = withContext(Dispatchers.IO) { loadUprightBitmap(path, ANALYSIS_MAX_SIDE) }
        if (bitmap == null) {
            Log.w(TAG, "Vision: cannot decode image at $path")
            return output
        }
        if (!requestModules()) {
            // 모듈을 내려받는 중이다. 이번 사진은 제안 없이 진행한다.
            return output
        }
        val image = InputImage.fromBitmap(bitmap, 0)
        // 분류와 배경 제거를 따로 실행해 한쪽 실패가 다른 쪽을 막지 않게 한다.
        try {
            output["labels"] = labeler.process(image).await().map {
                mapOf(
                    "identifier" to it.text.lowercase().replace(' ', '_'),
                    "confidence" to it.confidence.toDouble(),
                )
            }
        } catch (e: Exception) {
            Log.w(TAG, "Vision: classification failed: $e")
        }
        if (removeBackground) {
            try {
                val foreground = segmenter.process(image).await().foregroundBitmap
                val cutout = foreground?.let { withContext(Dispatchers.Default) { writeCutout(it) } }
                if (cutout != null) output["cutoutPath"] = cutout
            } catch (e: Exception) {
                Log.w(TAG, "Vision: background removal failed: $e")
            }
        }
        return output
    }

    /** 투명 영역을 잘라내고 [CUTOUT_MAX_SIDE]로 줄여 임시 PNG로 쓴다. 피사체가 너무 작으면 null. */
    private fun writeCutout(foreground: Bitmap): String? {
        val w = foreground.width
        val h = foreground.height
        val pixels = IntArray(w * h)
        foreground.getPixels(pixels, 0, w, 0, 0, w, h)
        var left = w
        var top = h
        var right = -1
        var bottom = -1
        for (y in 0 until h) {
            for (x in 0 until w) {
                if ((pixels[y * w + x] ushr 24) > 16) {
                    if (x < left) left = x
                    if (x > right) right = x
                    if (y < top) top = y
                    if (y > bottom) bottom = y
                }
            }
        }
        if (right < left || bottom < top) return null
        val cropW = right - left + 1
        val cropH = bottom - top + 1
        if (max(cropW, cropH) < CUTOUT_MIN_SIDE) return null
        var cropped = Bitmap.createBitmap(foreground, left, top, cropW, cropH)
        val longest = max(cropW, cropH)
        if (longest > CUTOUT_MAX_SIDE) {
            val scale = CUTOUT_MAX_SIDE.toFloat() / longest
            cropped = Bitmap.createScaledBitmap(
                cropped,
                (cropW * scale).toInt().coerceAtLeast(1),
                (cropH * scale).toInt().coerceAtLeast(1),
                true,
            )
        }
        val target = File(context.cacheDir, "closetimo_cutout_${UUID.randomUUID()}.png")
        FileOutputStream(target).use { cropped.compress(Bitmap.CompressFormat.PNG, 100, it) }
        return target.absolutePath
    }

    // ── 기기 내 AI (Gemini Nano) ──

    private suspend fun describe(path: String, schema: Map<String, List<String>>): Map<String, Any?> {
        val model = model ?: throw UnsupportedOperationException("Gemini Nano requires API 26+")
        if (model.checkStatus() != FeatureStatus.AVAILABLE) {
            throw UnsupportedOperationException("Gemini Nano is not available on this device")
        }
        val bitmap = withContext(Dispatchers.IO) { loadUprightBitmap(path, AI_MAX_SIDE) }
            ?: throw IllegalArgumentException("cannot decode image")
        val response = withTimeout(AI_TIMEOUT_MS) {
            model.generateContent(
                generateContentRequest(ImagePart(bitmap), TextPart(prompt(schema))) {
                    temperature = 0.1f
                    maxOutputTokens = 200
                },
            )
        }
        val text = response.candidates.firstOrNull()?.text
            ?: throw IllegalStateException("empty response")
        return parseDescription(text)
    }

    /** 허용 값 목록을 넣은 JSON 응답 지시문. 값 검증은 Dart가 다시 한다. */
    private fun prompt(schema: Map<String, List<String>>): String {
        fun values(key: String) = (schema[key] ?: emptyList()).joinToString(", ")
        return """
            You label a single clothing item from a photo for a personal wardrobe app.
            Describe only the garment itself, never the background, skin or hair.
            If a person wears several garments, describe the most prominent one.
            Answer with one JSON object only, no prose, using exactly these keys and allowed values
            (use "none" when unsure):
            {"category": one of [${values("category")}],
             "subType": one of [${values("subType")}, none],
             "colors": up to 3 of [${values("colors")}], most dominant first,
             "seasons": any of [${values("seasons")}],
             "material": one of [${values("material")}, none],
             "pattern": one of [${values("pattern")}, none]}
            subType hints: knit = any knitted sweater or pullover (British "jumper");
            jumper = casual zip-up outer jacket such as a bomber or windbreaker, never a sweater;
            cardigan = knit top that opens at the front; hoodie = hooded sweatshirt.
        """.trimIndent()
    }

    // ── 공통 ──

    /** EXIF 회전을 반영해 똑바로 세운 비트맵을 [maxSide] 안으로 줄여 읽는다. */
    private fun loadUprightBitmap(path: String, maxSide: Int): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
        var sample = 1
        while (max(bounds.outWidth, bounds.outHeight) / (sample * 2) >= maxSide) sample *= 2
        val decoded = BitmapFactory.decodeFile(
            path,
            BitmapFactory.Options().apply { inSampleSize = sample },
        ) ?: return null
        val degrees = try {
            when (ExifInterface(path).getAttributeInt(
                ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_NORMAL,
            )) {
                ExifInterface.ORIENTATION_ROTATE_90 -> 90f
                ExifInterface.ORIENTATION_ROTATE_180 -> 180f
                ExifInterface.ORIENTATION_ROTATE_270 -> 270f
                else -> 0f
            }
        } catch (e: Exception) {
            0f
        }
        if (degrees == 0f) return decoded
        val matrix = Matrix().apply { postRotate(degrees) }
        return Bitmap.createBitmap(decoded, 0, 0, decoded.width, decoded.height, matrix, true)
    }

    companion object {
        const val CHANNEL = "closetimo/vision"
        private const val TAG = "ClosetimoVision"

        /** Dart로 넘길 라벨의 최소 신뢰도. 최종 판정(0.6)은 Dart가 한다. */
        private const val LABEL_MIN_CONFIDENCE = 0.3f
        private const val ANALYSIS_MAX_SIDE = 1024
        private const val AI_MAX_SIDE = 768
        private const val CUTOUT_MAX_SIDE = 1024
        private const val CUTOUT_MIN_SIDE = 48
        private const val AI_TIMEOUT_MS = 20_000L

        /**
         * 모델 응답에서 JSON 객체를 꺼내 채널 응답 맵으로 바꾼다. 앞뒤 설명·코드 펜스는 무시한다.
         * 알 수 없는 값의 정리는 Dart(`AttributeSuggester.fromDescription`)가 한다.
         */
        fun parseDescription(text: String): Map<String, Any?> {
            val start = text.indexOf('{')
            val end = text.lastIndexOf('}')
            if (start < 0 || end <= start) throw IllegalStateException("no JSON in response")
            val json = JSONObject(text.substring(start, end + 1))
            fun list(key: String): List<String> {
                val raw = json.opt(key)
                return when (raw) {
                    is JSONArray -> (0 until raw.length()).map { raw.optString(it) }
                    is String -> listOf(raw)
                    else -> emptyList()
                }.map { it.trim().lowercase() }.filter { it.isNotEmpty() }
            }
            fun text(key: String): String? =
                json.optString(key, "").trim().lowercase().ifEmpty { null }
            return mapOf(
                "category" to text("category"),
                "subType" to text("subType"),
                "colors" to list("colors"),
                "seasons" to list("seasons"),
                "material" to text("material"),
                "pattern" to text("pattern"),
            )
        }
    }
}
