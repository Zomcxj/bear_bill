package com.bearbill.bear_bill

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodChannel

/**
 * 通知监听服务 - 监听微信/支付宝支付通知，自动记账
 */
class NotificationListenerServiceImpl : NotificationListenerService() {

    private var lastDebugTime = 0L
    private var notificationCount = 0

    companion object {
        private const val TAG = "AutoRecord"
        private const val CHANNEL_ID = "auto_record"
        private const val DEBUG_COOLDOWN_MS = 0L // 调试：每个通知都弹

        // 监听的包名
        private val TARGET_PACKAGES = setOf(
            "com.eg.android.AlipayGphone", // 支付宝
            // 主流银行 app
            "cmb.pb",                      // 招商银行
            "com.icbc",                    // 工商银行
            "com.ccb.start",               // 建设银行
            "com.abchina.phone",           // 农业银行
            "com.chinamworld.bocmbci",     // 中国银行
            "com.bankcomm.Bankcomm",       // 交通银行
            "com.spdb.mobilebank.nfc",     // 浦发银行
            "com.pingan.paces.ccms",       // 平安银行
            "com.yitong.mbank.psbc",       // 邮储银行
            "com.cebbank.mobile.cemb",     // 光大银行
            "com.cmbc.cc.mbank",           // 民生银行
            "com.cib.cibmb",               // 兴业银行
            "com.ecitic.bank.mobile",      // 中信银行
            "com.hua.xia",                 // 华夏银行
            "com.eg.android.GJBWebBankingService", // 广发银行
            "com.bochk.com",               // 华商银行
            "com.unionpay"                 // 云闪付
        )
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        // 记录服务启动状态
        val prefs = getSharedPreferences("auto_record_prefs", MODE_PRIVATE)
        prefs.edit().putBoolean("listener_running", true).apply()
        Log.d(TAG, "通知监听服务已启动")
    }

    override fun onDestroy() {
        super.onDestroy()
        val prefs = getSharedPreferences("auto_record_prefs", MODE_PRIVATE)
        prefs.edit().putBoolean("listener_running", false).apply()
        Log.d(TAG, "通知监听服务已销毁")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return

        val packageName = sbn.packageName ?: return

        val notification = sbn.notification ?: return
        val extras = notification.extras ?: return

        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extractNotificationText(extras)

        // 调试：所有通知都弹窗（用于验证通知监听是否工作）
        notificationCount++
        val now = System.currentTimeMillis()
        // 存到 SharedPreferences 供 Flutter 读取
        val debugPrefs = getSharedPreferences("auto_record_prefs", MODE_PRIVATE)
        debugPrefs.edit()
            .putString("last_notification_package", packageName)
            .putString("last_notification_title", title)
            .putString("last_notification_text", text)
            .putLong("last_notification_time", now)
            .putInt("notification_count", notificationCount)
            .apply()
        // 每个通知都弹调试窗
        showDebugNotification(
            "[$notificationCount] 收到通知",
            "来源: $packageName\n标题: $title\n内容: $text"
        )

        // 只处理支付相关通知（通过关键词匹配，不过滤包名）
        val isPayment = isPaymentNotification(title, text, packageName)
        Log.d(TAG, "通知检查: pkg=$packageName, title=$title, isPayment=$isPayment")
        if (!isPayment) return

        Log.d(TAG, "捕获支付通知: [$title] $text")

        val source = when {
            packageName.contains("Alipay") -> "alipay"
            else -> "bank"
        }

        // 1. 把支付数据存到 SharedPreferences（Flutter 打开时可以读取）
        val prefs = getSharedPreferences("auto_record_prefs", MODE_PRIVATE)
        prefs.edit()
            .putString("pending_title", title)
            .putString("pending_text", text)
            .putString("pending_source", source)
            .putLong("pending_timestamp", System.currentTimeMillis())
            .apply()

        // 2. 直接发系统通知（不依赖 Flutter 引擎）
        showPaymentNotification(title, text, source)

        // 3. 尝试推送给 Flutter（如果引擎可用）
        try {
            val engine = MainActivity.flutterEngine
            if (engine != null) {
                val data = mapOf(
                    "title" to title,
                    "text" to text,
                    "source" to source,
                    "timestamp" to System.currentTimeMillis()
                )
                MethodChannel(engine.dartExecutor.binaryMessenger, "bear_bill/auto_record")
                    .invokeMethod("onPaymentNotification", data, null)
                Log.d(TAG, "已推送给 Flutter")
            } else {
                Log.d(TAG, "Flutter 引擎不可用，数据已存到 SharedPreferences")
            }
        } catch (e: Exception) {
            Log.e(TAG, "MethodChannel 推送失败", e)
        }
    }

    private fun isPaymentNotification(title: String, text: String, packageName: String): Boolean {
        val content = "$title $text"

        // 通用支付关键词（适用于所有 app：支付宝、银行、云闪付等）
        val paymentKeywords = listOf(
            // 支出类
            "支出", "消费", "付款", "转出", "扣款", "取现", "缴费",
            "支付成功", "付款成功", "转账成功", "已付款", "已支付",
            "交易成功", "交易完成",
            // 收入类
            "收入", "转入", "到账", "收款", "存入", "收款成功",
            // 支付宝特有
            "余额宝", "花呗", "借呗", "交易通知", "账户变动", "资金变动",
            // 银行特有
            "人民币", "账户余额"
        )
        return paymentKeywords.any { content.contains(it) }
    }

    private fun extractNotificationText(extras: android.os.Bundle): String {
        val parts = mutableListOf<String>()

        extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()?.let { parts.add(it) }
        extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()?.let { parts.add(it) }
        extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString()?.let { parts.add(it) }
        extras.getCharSequence(Notification.EXTRA_SUMMARY_TEXT)?.toString()?.let { parts.add(it) }

        val lines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
        if (lines != null) {
            for (line in lines) {
                val value = line?.toString()
                if (!value.isNullOrBlank()) parts.add(value)
            }
        }

        return parts
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .distinct()
            .joinToString(" ")
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "自动记账通知",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "自动记账功能的状态通知"
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun showPaymentNotification(title: String, text: String, source: String) {
        try {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    "auto_record_payment",
                    "自动记账",
                    NotificationManager.IMPORTANCE_HIGH
                )
                manager.createNotificationChannel(channel)
            }

            val sourceLabel = when (source) {
                "alipay" -> "支付宝"
                else -> "银行"
            }

            // 点击通知打开 app
            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            val pendingIntent = PendingIntent.getActivity(
                this, 0, launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val notification = NotificationCompat.Builder(this, "auto_record_payment")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle("🐻 检测到${sourceLabel}支付")
                .setContentText("$title $text · 点击确认记账")
                .setStyle(NotificationCompat.BigTextStyle().bigText("$title $text"))
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)
                .build()

            manager.notify(777, notification)
            Log.d(TAG, "已发送支付确认通知")
        } catch (e: Exception) {
            Log.e(TAG, "发送支付通知失败", e)
        }
    }

    private fun showDebugNotification(title: String, text: String) {
        try {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val debugChannel = NotificationChannel(
                    "auto_record_debug",
                    "自动记账调试",
                    NotificationManager.IMPORTANCE_HIGH
                )
                manager.createNotificationChannel(debugChannel)
            }

            val notification = NotificationCompat.Builder(this, "auto_record_debug")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle("🔍 $title")
                .setContentText(text)
                .setStyle(NotificationCompat.BigTextStyle().bigText(text))
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .build()

            manager.notify(System.currentTimeMillis().toInt(), notification)
        } catch (e: Exception) {
            Log.e(TAG, "显示调试通知失败", e)
        }
    }
}
