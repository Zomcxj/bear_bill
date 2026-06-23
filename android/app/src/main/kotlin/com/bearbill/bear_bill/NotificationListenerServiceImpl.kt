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
import io.flutter.plugin.common.MethodChannel

/**
 * 通知监听服务 - 监听微信/支付宝支付通知，自动记账
 */
class NotificationListenerServiceImpl : NotificationListenerService() {

    companion object {
        private const val TAG = "AutoRecord"
        private const val CHANNEL_ID = "auto_record"

        // 监听的包名
        private val TARGET_PACKAGES = setOf(
            "com.tencent.mm",              // 微信
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
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return

        val packageName = sbn.packageName ?: return
        if (packageName !in TARGET_PACKAGES) return

        // 不在这里检查 auto_record_prefs 开关（跨进程 SharedPreferences 隔离，读不到）
        // 始终处理支付通知，由 Flutter 端决定是否记录

        val notification = sbn.notification ?: return
        val extras = notification.extras ?: return

        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""

        // 只处理支付通知
        if (!isPaymentNotification(title, text, packageName)) return

        Log.d(TAG, "捕获支付通知: [$title] $text")

        // 通过 MethodChannel 直接推送给 Flutter（解决跨进程 SharedPreferences 隔离问题）
        try {
            val engine = MainActivity.flutterEngine
            if (engine == null) {
                Log.w(TAG, "FlutterEngine 不可用，通知丢弃")
                return
            }

            val source = when {
                packageName.contains("tencent") -> "wechat"
                packageName.contains("Alipay") -> "alipay"
                else -> "bank"
            }

            val data = mapOf(
                "title" to title,
                "text" to text,
                "source" to source,
                "timestamp" to System.currentTimeMillis()
            )

            MethodChannel(engine.dartExecutor.binaryMessenger, "bear_bill/auto_record")
                .invokeMethod("onPaymentNotification", data, null)

            Log.d(TAG, "通知已通过 MethodChannel 推送给 Flutter")
        } catch (e: Exception) {
            Log.e(TAG, "MethodChannel 推送失败", e)
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

        // 银行 app 关键词
        val bankKeywords = listOf(
            "支出", "消费", "转出", "扣款", "付款",
            "取现", "转账", "缴费", "支付", "人民币",
            "收入", "转入", "到账", "收款", "存入"
        )
        return bankKeywords.any { content.contains(it) }
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
