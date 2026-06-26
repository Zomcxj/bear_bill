package com.bearbill.bear_bill

import android.content.ComponentName
import android.content.Intent
import android.location.Geocoder
import android.net.Uri
import android.provider.OpenableColumns
import android.provider.Settings
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import java.io.File
import java.io.FileOutputStream
import java.util.Locale
import java.util.concurrent.TimeUnit

class MainActivity : FlutterFragmentActivity() {

    companion object {
        // 供 NotificationListenerService 调用，实现反向 MethodChannel 推送
        var flutterEngine: FlutterEngine? = null
            private set
    }

    private var pendingExportResult: MethodChannel.Result? = null
    private var pendingImportResult: MethodChannel.Result? = null
    private var pendingExportSourcePath: String? = null

    private lateinit var exportDocumentLauncher: ActivityResultLauncher<String>
    private lateinit var importDocumentLauncher: ActivityResultLauncher<Array<String>>

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 暴露 FlutterEngine 引用，供 NotificationListenerService 反向推送
        MainActivity.flutterEngine = flutterEngine

        // 启动时检查并恢复闹钟（防止被系统杀掉后丢失）
        AlarmScheduler.ensureScheduled(this)

        // 注册 WorkManager 周期任务作为闹钟兜底
        val workRequest = PeriodicWorkRequestBuilder<ReminderWorker>(15, TimeUnit.MINUTES)
            .build()
        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            "daily_reminder_check",
            ExistingPeriodicWorkPolicy.KEEP,
            workRequest
        )

        // 注册文件导出 launcher
        exportDocumentLauncher = registerForActivityResult(
            ActivityResultContracts.CreateDocument("*/*")
        ) { uri ->
            val result = pendingExportResult
            val sourcePath = pendingExportSourcePath
            pendingExportResult = null
            pendingExportSourcePath = null

            if (result == null) return@registerForActivityResult
            if (uri == null || sourcePath.isNullOrBlank()) {
                result.success(null)
                return@registerForActivityResult
            }

            try {
                val sourceFile = File(sourcePath)
                contentResolver.openOutputStream(uri)?.use { output ->
                    sourceFile.inputStream().use { input ->
                        input.copyTo(output)
                    }
                } ?: throw IllegalStateException("无法写入目标文件")

                result.success(uri.toString())
            } catch (e: Exception) {
                result.error("export_failed", e.message, null)
            }
        }

        // 注册文件导入 launcher
        importDocumentLauncher = registerForActivityResult(
            ActivityResultContracts.OpenDocument()
        ) { uri ->
            val result = pendingImportResult
            pendingImportResult = null

            if (result == null) return@registerForActivityResult
            if (uri == null) {
                result.success(null)
                return@registerForActivityResult
            }

            try {
                val fileName = queryDisplayName(uri) ?: "bear_bill_import.db"
                val tempFile = File(cacheDir, fileName)

                contentResolver.openInputStream(uri)?.use { input ->
                    tempFile.outputStream().use { output ->
                        input.copyTo(output)
                    }
                } ?: throw IllegalStateException("无法读取所选文件")

                result.success(tempFile.absolutePath)
            } catch (e: Exception) {
                result.error("import_failed", e.message, null)
            }
        }

        // 位置相关 MethodChannel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "bear_bill/location"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "reverseGeocode" -> {
                    val latitude = call.argument<Double>("latitude")
                    val longitude = call.argument<Double>("longitude")

                    if (latitude == null || longitude == null) {
                        result.error("invalid_args", "Missing latitude or longitude.", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val geocoder = Geocoder(this, Locale.getDefault())
                        val addresses = geocoder.getFromLocation(latitude, longitude, 1)
                        val address = addresses
                            ?.firstOrNull()
                            ?.getAddressLine(0)
                            ?.takeIf { it.isNotBlank() }

                        result.success(address)
                    } catch (e: Exception) {
                        result.error("reverse_geocode_failed", e.message, null)
                    }
                }

                "openMap" -> {
                    val latitude = call.argument<Double>("latitude")
                    val longitude = call.argument<Double>("longitude")
                    val query = call.argument<String>("query")?.trim().orEmpty()

                    try {
                        val uri = when {
                            latitude != null && longitude != null -> {
                                val label = Uri.encode(if (query.isBlank()) "当前位置" else query)
                                Uri.parse("geo:$latitude,$longitude?q=$latitude,$longitude($label)")
                            }

                            query.isNotBlank() -> {
                                Uri.parse("geo:0,0?q=${Uri.encode(query)}")
                            }

                            else -> {
                                Uri.parse("geo:0,0?q=${Uri.encode("附近位置")}")
                            }
                        }

                        val mapIntent = Intent(Intent.ACTION_VIEW, uri).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }

                        if (mapIntent.resolveActivity(packageManager) != null) {
                            startActivity(mapIntent)
                            result.success(true)
                        } else {
                            result.error("map_unavailable", "No map app available.", null)
                        }
                    } catch (e: Exception) {
                        result.error("open_map_failed", e.message, null)
                    }
                }

                "searchLocation" -> {
                    val query = call.argument<String>("query")
                    if (query.isNullOrBlank()) {
                        result.error("invalid_args", "Missing query.", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val geocoder = Geocoder(this, Locale.getDefault())
                        @Suppress("DEPRECATION")
                        val addresses = geocoder.getFromLocationName(query, 10)
                        val resultList = addresses?.map { addr ->
                            mapOf(
                                "featureName" to (addr.featureName ?: ""),
                                "addressLine" to (addr.getAddressLine(0) ?: ""),
                                "latitude" to addr.latitude,
                                "longitude" to addr.longitude
                            )
                        } ?: emptyList()
                        result.success(resultList)
                    } catch (e: Exception) {
                        result.error("search_failed", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }

        // 闹钟提醒 MethodChannel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "bear_bill/alarm"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    val hour = call.argument<Int>("hour") ?: 0
                    val minute = call.argument<Int>("minute") ?: 0

                    val prefs = getSharedPreferences("alarm_prefs", MODE_PRIVATE)
                    prefs.edit()
                        .putInt("reminder_hour", hour)
                        .putInt("reminder_minute", minute)
                        .remove("last_fire_date")
                        .apply()

                    AlarmScheduler.scheduleDaily(this, hour, minute)
                    result.success(true)
                }

                "cancelAlarm" -> {
                    val prefs = getSharedPreferences("alarm_prefs", MODE_PRIVATE)
                    prefs.edit().remove("reminder_hour").remove("reminder_minute").apply()

                    AlarmScheduler.cancel(this)
                    WorkManager.getInstance(this).cancelUniqueWork("daily_reminder_check")
                    result.success(true)
                }

                "openBatterySettings" -> {
                    try {
                        // 跳转到电池优化设置页，让用户关闭本 App 的电池优化
                        val intent = Intent(android.provider.Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("open_failed", e.message, null)
                    }
                }

                "updateTodaySummary" -> {
                    val count = call.argument<Int>("count") ?: 0
                    val expense = call.argument<Double>("expense") ?: 0.0
                    val income = call.argument<Double>("income") ?: 0.0
                    val today = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.getDefault())
                        .format(java.util.Date())
                    val prefs = getSharedPreferences("alarm_prefs", MODE_PRIVATE)
                    prefs.edit()
                        .putString("summary_date", today)
                        .putInt("today_count", count)
                        .putFloat("today_expense", expense.toFloat())
                        .putFloat("today_income", income.toFloat())
                        .apply()
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }

        // 文件导入导出 MethodChannel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "bear_bill/files"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "exportFile" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    val suggestedFileName = call.argument<String>("suggestedFileName")

                    if (sourcePath.isNullOrBlank() || suggestedFileName.isNullOrBlank()) {
                        result.error("invalid_args", "Missing source path or file name.", null)
                        return@setMethodCallHandler
                    }

                    if (!File(sourcePath).exists()) {
                        result.error("source_missing", "Source file does not exist.", null)
                        return@setMethodCallHandler
                    }

                    pendingExportResult = result
                    pendingExportSourcePath = sourcePath
                    exportDocumentLauncher.launch(suggestedFileName)
                }

                "pickFile" -> {
                    pendingImportResult = result
                    importDocumentLauncher.launch(arrayOf("*/*"))
                }

                else -> result.notImplemented()
            }
        }

        // 自动记账 MethodChannel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "bear_bill/auto_record"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isListenerEnabled" -> {
                    val componentName = ComponentName(this, NotificationListenerServiceImpl::class.java)
                    val enabledListeners = Settings.Secure.getString(
                        contentResolver,
                        "enabled_notification_listeners"
                    )
                    val isEnabled = enabledListeners?.contains(componentName.flattenToString()) == true
                    result.success(isEnabled)
                }

                "openListenerSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("open_failed", e.message, null)
                    }
                }

                "isAccessibilityEnabled" -> {
                    try {
                        val enabledServices = Settings.Secure.getString(
                            contentResolver,
                            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
                        ) ?: ""
                        // 兼容两种格式：完整 ComponentName 和缩写格式
                        val fullComponentName = ComponentName(this, PaymentAccessibilityService::class.java).flattenToString()
                        val shortComponentName = ComponentName(this, PaymentAccessibilityService::class.java).flattenToShortString()
                        val isEnabled = enabledServices.contains(fullComponentName) || enabledServices.contains(shortComponentName)
                        android.util.Log.d("AutoRecord_A11y", "无障碍检测: enabledServices=$enabledServices, full=$fullComponentName, short=$shortComponentName, result=$isEnabled")
                        result.success(isEnabled)
                    } catch (e: Exception) {
                        android.util.Log.e("AutoRecord_A11y", "检测无障碍状态失败", e)
                        result.success(false)
                    }
                }

                "openAccessibilitySettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("open_failed", e.message, null)
                    }
                }

                // 读取自动记账开关状态（与 NotificationListenerServiceImpl 使用相同 prefs 文件）
                "getAutoRecordEnabled" -> {
                    val prefs = getSharedPreferences("auto_record_prefs", MODE_PRIVATE)
                    result.success(prefs.getBoolean("enabled", false))
                }

                // 设置自动记账开关状态
                "setAutoRecordEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    val prefs = getSharedPreferences("auto_record_prefs", MODE_PRIVATE)
                    prefs.edit().putBoolean("enabled", enabled).apply()
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }

        // 语音录音 MethodChannel（使用 Android 原生 AudioRecord 录制 PCM，支持静音自动停止）
        var audioRecord: AudioRecord? = null
        var recordingThread: Thread? = null
        var isRecording = false
        var recordingFilePath: String? = null
        var autoStoppedBySilence = false
        val speechChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "bear_bill/speech")

        speechChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startRecording" -> {
                    try {
                        val sampleRate = 16000
                        val channelConfig = AudioFormat.CHANNEL_IN_MONO
                        val audioFormat = AudioFormat.ENCODING_PCM_16BIT
                        val bufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)

                        audioRecord = AudioRecord(
                            MediaRecorder.AudioSource.MIC,
                            sampleRate,
                            channelConfig,
                            audioFormat,
                            bufferSize * 2
                        )

                        if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
                            result.error("init_failed", "AudioRecord 初始化失败", null)
                            return@setMethodCallHandler
                        }

                        val tempFile = File(cacheDir, "speech_${System.currentTimeMillis()}.pcm")
                        recordingFilePath = tempFile.absolutePath
                        isRecording = true
                        autoStoppedBySilence = false

                        audioRecord?.startRecording()

                        // 后台线程写入 PCM 数据 + 静音检测
                        recordingThread = Thread {
                            val buffer = ByteArray(bufferSize)
                            val outputStream = FileOutputStream(tempFile)
                            var silenceStart = 0L
                            val silenceThreshold = 500  // PCM 16-bit 振幅阈值
                            val silenceTimeout = 2000L  // 静音 2 秒自动停止
                            var hasVoice = false  // 是否检测到过语音

                            try {
                                while (isRecording) {
                                    val read = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                                    if (read > 0) {
                                        outputStream.write(buffer, 0, read)

                                        // 计算振幅
                                        var sum = 0
                                        for (i in 0 until read step 2) {
                                            val sample = (buffer[i].toInt() and 0xFF) or (buffer[i + 1].toInt() shl 8)
                                            sum += kotlin.math.abs(sample.toShort().toInt())
                                        }
                                        val avgAmplitude = if (read > 1) sum / (read / 2) else 0

                                        if (avgAmplitude > silenceThreshold) {
                                            silenceStart = 0
                                            hasVoice = true
                                        } else if (hasVoice) {
                                            // 检测到语音后才开始计算静音
                                            if (silenceStart == 0L) {
                                                silenceStart = System.currentTimeMillis()
                                            } else if (System.currentTimeMillis() - silenceStart > silenceTimeout) {
                                                // 静音超时，自动停止
                                                autoStoppedBySilence = true
                                                isRecording = false
                                            }
                                        }
                                    }
                                }
                            } catch (_: Exception) {
                            } finally {
                                outputStream.close()
                            }
                        }
                        recordingThread?.start()

                        result.success(true)
                    } catch (e: Exception) {
                        result.error("start_failed", e.message, null)
                    }
                }

                "stopRecording" -> {
                    try {
                        isRecording = false
                        Thread.sleep(200)
                        audioRecord?.stop()
                        audioRecord?.release()
                        audioRecord = null
                        recordingThread = null
                        val response = mapOf(
                            "path" to recordingFilePath,
                            "autoStopped" to autoStoppedBySilence
                        )
                        result.success(response)
                    } catch (e: Exception) {
                        result.error("stop_failed", e.message, null)
                    }
                }

                "isRecording" -> {
                    result.success(isRecording)
                }

                "cancelRecording" -> {
                    try {
                        isRecording = false
                        audioRecord?.stop()
                        audioRecord?.release()
                        audioRecord = null
                        recordingThread = null
                        recordingFilePath?.let { File(it).delete() }
                        recordingFilePath = null
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("cancel_failed", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun queryDisplayName(uri: Uri): String? {
        contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (nameIndex >= 0 && cursor.moveToFirst()) {
                return cursor.getString(nameIndex)
            }
        }
        return null
    }
}
