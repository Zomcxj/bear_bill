package com.bearbill.bear_bill

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import androidx.core.app.NotificationCompat
import org.json.JSONObject

/**
 * 通知监听服务 - 监听微信/支付宝支付通知，自动记账
 */
class NotificationListenerServiceImpl : NotificationListenerService() {

    companion object {
        private const val TAG = "AutoRecord"
        private const val CHANNEL_ID = "auto_record"

        // 监听的包名
        private val TARGET_PACKAGES = setOf(
            "com.tencent.mm",          // 微信
            "com.eg.android.AlipayGphone" // 支付宝
        )
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return

        val packageName = sbn.packageName ?: return
        if (packageName !in TARGET_PACKAGES) return

        // 检查是否启用了自动记账
        val prefs = getSharedPreferences("auto_record_prefs", MODE_PRIVATE)
        val enabled = prefs.getBoolean("enabled", false)
        if (!enabled) return

        val notification = sbn.notification ?: return
        val extras = notification.extras ?: return

        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""

        // 只处理支付通知
        if (!isPaymentNotification(title, text, packageName)) return

        Log.d(TAG, "捕获支付通知: [$title] $text")

        // 通过 SharedPreferences 存储，Flutter 端轮询读取
        // 使用与 MainActivity 相同的 prefs 文件
        try {
            val json = JSONObject().apply {
                put("title", title)
                put("text", text)
                put("source", if (packageName.contains("tencent")) "wechat" else "alipay")
                put("timestamp", System.currentTimeMillis())
            }
            prefs.edit().putString("pending_notification", json.toString()).apply()
            Log.d(TAG, "通知已存储到 SharedPreferences")
        } catch (e: Exception) {
            Log.e(TAG, "存储通知失败", e)
        }
    }

    private fun isPaymentNotification(title: String, text: String, packageName: String): Boolean {
        val content = "$title $text"

        // 微信支付关键词
        if (packageName.contains("tencent")) {
            val wechatKeywords = listOf(
                "微信支付", "支付成功", "付款成功", "转账",
                "收款", "已收钱", "已付款", "红包"
            )
            return wechatKeywords.any { content.contains(it) }
        }

        // 支付宝关键词
        if (packageName.contains("Alipay")) {
            val alipayKeywords = listOf(
                "支付成功", "付款成功", "转账成功",
                "已付款", "已支付", "收款成功"
            )
            return alipayKeywords.any { content.contains(it) }
        }

        return false
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
}
