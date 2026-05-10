package com.bearbill.bear_bill

import android.content.Intent
import android.location.Geocoder
import android.net.Uri
import android.provider.OpenableColumns
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.Locale

class MainActivity : FlutterFragmentActivity() {
    private var pendingExportResult: MethodChannel.Result? = null
    private var pendingImportResult: MethodChannel.Result? = null
    private var pendingExportSourcePath: String? = null

    private lateinit var exportDocumentLauncher: ActivityResultLauncher<String>
    private lateinit var importDocumentLauncher: ActivityResultLauncher<Array<String>>

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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

                    // 保存到 SharedPreferences（开机自启时恢复）
                    val prefs = getSharedPreferences("alarm_prefs", MODE_PRIVATE)
                    prefs.edit()
                        .putInt("reminder_hour", hour)
                        .putInt("reminder_minute", minute)
                        .apply()

                    AlarmScheduler.scheduleDaily(this, hour, minute)
                    result.success(true)
                }

                "cancelAlarm" -> {
                    val prefs = getSharedPreferences("alarm_prefs", MODE_PRIVATE)
                    prefs.edit().remove("reminder_hour").remove("reminder_minute").apply()

                    AlarmScheduler.cancel(this)
                    result.success(true)
                }

                "markRecordedToday" -> {
                    val today = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.getDefault())
                        .format(java.util.Date())
                    val prefs = getSharedPreferences("alarm_prefs", MODE_PRIVATE)
                    prefs.edit().putString("last_recorded_date", today).apply()
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
