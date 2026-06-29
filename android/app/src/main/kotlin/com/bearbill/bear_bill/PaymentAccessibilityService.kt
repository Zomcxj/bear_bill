package com.bearbill.bear_bill

import android.accessibilityservice.AccessibilityService
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodChannel
import java.util.regex.Pattern

/**
 * 支付无障碍服务 - 监听微信/支付宝支付成功页面，自动提取金额
 */
class PaymentAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "AutoRecord_A11y"
        private const val COOLDOWN_MS = 10000L // 10秒内不重复处理同一笔

        // 监听的包名（与 NotificationListenerServiceImpl 保持一致）
        private val TARGET_PACKAGES = setOf(
            "com.eg.android.AlipayGphone", // 支付宝
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

        // 微信支付成功页面的关键文本
        private val WECHAT_SUCCESS_KEYWORDS = listOf(
            "支付成功", "付款成功", "转账成功", "已转账",
            "红包已发出", "已收钱"
        )

        // 支付宝支付成功页面的关键文本
        private val ALIPAY_SUCCESS_KEYWORDS = listOf(
            "支付成功", "付款成功", "转账成功", "已成功付款",
            "收款成功", "已付款"
        )

        // 银行 app 支付相关关键词
        private val BANK_SUCCESS_KEYWORDS = listOf(
            "支付成功", "付款成功", "转账成功", "交易成功",
            "扣款成功", "消费成功", "缴费成功",
            "支出", "消费", "转出", "扣款", "已付款",
            "已支付", "交易完成"
        )

        // 金额匹配模式
        val AMOUNT_PATTERNS = listOf(
            Pattern.compile("[¥￥]\\s*(\\d+\\.?\\d{0,2})"),
            Pattern.compile("(\\d+\\.\\d{2})\\s*元"),
            Pattern.compile("金额\\s*[¥￥]?\\s*(\\d+\\.?\\d{0,2})"),
            Pattern.compile("支出\\s*[¥￥]?\\s*(\\d+\\.?\\d{0,2})"),
            Pattern.compile("消费\\s*[¥￥]?\\s*(\\d+\\.?\\d{0,2})"),
            Pattern.compile("扣款\\s*[¥￥]?\\s*(\\d+\\.?\\d{0,2})"),
        )
    }

    private var lastProcessedTime = 0L
    private var lastProcessedText = ""
    private var lastDebugTime = 0L
    private var lastFloatingWindowTime = 0L

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "无障碍服务已连接")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val packageName = event.packageName?.toString() ?: return

        // 处理通知事件（替代 NotificationListenerService）
        if (event.eventType == AccessibilityEvent.TYPE_NOTIFICATION_STATE_CHANGED) {
            handleNotificationEvent(event, packageName)
            return
        }

        // 只处理目标 app 的窗口事件
        if (packageName !in TARGET_PACKAGES) return

        val isAlipay = packageName.contains("Alipay")

        // 支付宝只处理窗口状态切换事件，避免历史交易列表加载时误触发
        if (isAlipay) {
            if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        } else {
            if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
                event.eventType != AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) return
        }

        try {
            val rootNode = rootInActiveWindow ?: return
            val screenText = extractAllText(rootNode)

            if (screenText.length < 5) return

            // 冷却检查：避免同一笔支付重复触发
            val now = System.currentTimeMillis()
            if (now - lastProcessedTime < COOLDOWN_MS && screenText == lastProcessedText) return

            val isWechat = packageName.contains("tencent")
            val isBank = !isWechat && !isAlipay

            // 根据来源选择关键词
            val keywords = when {
                isWechat -> WECHAT_SUCCESS_KEYWORDS
                isAlipay -> ALIPAY_SUCCESS_KEYWORDS
                else -> BANK_SUCCESS_KEYWORDS
            }
            val isPaymentSuccess = keywords.any { screenText.contains(it) }

            if (!isPaymentSuccess) return

            // 支付宝额外保护：要求 "支付成功" 只出现一次
            // 历史交易页面可能有多笔 "支付成功" 文本，过滤掉
            if (isAlipay) {
                val count = screenText.split("支付成功").size - 1
                if (count > 1) {
                    Log.d(TAG, "支付宝历史页面, 跳过")
                    return
                }
            }

            // 提取金额
            val amount = extractAmount(screenText)
            if (amount == null || amount <= 0) return

            // 提取商户/描述
            val merchant = extractMerchant(screenText, isWechat)

            val sourceLabel = when {
                isWechat -> "微信"
                isAlipay -> "支付宝"
                else -> "银行"
            }
            Log.d(TAG, "检测到${sourceLabel}支付成功: ¥$amount ${merchant ?: ""}")

            lastProcessedTime = now
            lastProcessedText = screenText

            // 构造通知文本
            val notificationTitle = "${sourceLabel}支付"
            val notificationText = "¥$amount ${merchant ?: ""}"

            // 1. 存到 SharedPreferences（Flutter 打开时读取）
            val prefs = getSharedPreferences("auto_record_prefs", MODE_PRIVATE)
            prefs.edit()
                .putString("pending_title", notificationTitle)
                .putString("pending_text", notificationText)
                .putString("pending_source", if (isWechat) "wechat" else if (isAlipay) "alipay" else "bank")
                .putLong("pending_timestamp", System.currentTimeMillis())
                .apply()

            // 2. 发系统通知
            showPaymentNotification(notificationTitle, notificationText, if (isWechat) "wechat" else if (isAlipay) "alipay" else "bank")

            // 3. 尝试推送给 Flutter
            try {
                val engine = MainActivity.flutterEngine
                if (engine != null) {
                    pushToFlutter(amount, merchant, isWechat, isAlipay)
                    Log.d(TAG, "已推送给 Flutter")
                } else {
                    Log.d(TAG, "Flutter 引擎不可用，数据已存到 SharedPreferences")
                }
            } catch (e: Exception) {
                Log.e(TAG, "推送给 Flutter 失败", e)
            }

        } catch (e: Exception) {
            Log.e(TAG, "处理无障碍事件失败", e)
        }
    }

    /**
     * 处理通知事件（替代 NotificationListenerService）
     * 当系统收到通知时，无障碍服务会收到 TYPE_NOTIFICATION_STATE_CHANGED 事件
     */
    private fun handleNotificationEvent(event: AccessibilityEvent, packageName: String) {
        try {
            // 提取通知文本
            val text = event.text?.joinToString(" ") ?: ""
            if (text.isEmpty()) return

            Log.d(TAG, "收到通知事件: pkg=$packageName, text=$text")

            // 检查是否是支付通知
            val isPayment = isPaymentNotification(text, packageName)
            if (!isPayment) return

            Log.d(TAG, "无障碍检测到支付通知: $text")

            // 提取金额
            val amount = extractAmount(text)
            if (amount == null || amount <= 0) return

            val source = when {
                packageName.contains("Alipay") -> "alipay"
                packageName.contains("tencent") -> "wechat"
                else -> "bank"
            }
            val sourceLabel = when (source) {
                "alipay" -> "支付宝"
                "wechat" -> "微信"
                else -> "银行"
            }

            // 显示通知（点击进入编辑页面，60秒冷却）
            val notifyNow = System.currentTimeMillis()
            if (notifyNow - lastFloatingWindowTime > 60000L) {
                lastFloatingWindowTime = notifyNow
                showPaymentNotification("${sourceLabel}支付", "¥$amount", source)
                Log.d(TAG, "已发送支付通知: $sourceLabel ¥$amount")
            } else {
                Log.d(TAG, "通知冷却中，跳过")
            }
        } catch (e: Exception) {
            Log.e(TAG, "处理通知事件失败", e)
        }
    }

    private fun isPaymentNotification(text: String, packageName: String): Boolean {
        val paymentKeywords = listOf(
            "支出", "消费", "付款", "转出", "扣款", "取现", "缴费",
            "支付成功", "付款成功", "转账成功", "已付款", "已支付",
            "交易成功", "交易完成",
            "收入", "转入", "到账", "收款", "存入", "收款成功",
            "余额宝", "花呗", "借呗", "交易通知", "账户变动", "资金变动",
            "人民币", "账户余额"
        )
        return paymentKeywords.any { text.contains(it) }
    }

    /**
     * 递归提取节点及其子节点的所有文本
     */
    private fun extractAllText(node: AccessibilityNodeInfo): String {
        val sb = StringBuilder()
        if (node.text != null) {
            sb.append(node.text.toString()).append(" ")
        }
        if (node.contentDescription != null) {
            sb.append(node.contentDescription.toString()).append(" ")
        }
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            sb.append(extractAllText(child))
            child.recycle()
        }
        return sb.toString()
    }

    /**
     * 从文本中提取金额
     */
    private fun extractAmount(text: String): Double? {
        for (pattern in AMOUNT_PATTERNS) {
            val matcher = pattern.matcher(text)
            if (matcher.find()) {
                val amountStr = matcher.group(1) ?: continue
                val amount = amountStr.toDoubleOrNull()
                if (amount != null && amount > 0 && amount < 1000000) {
                    return amount
                }
            }
        }
        return null
    }

    /**
     * 提取商户名称
     */
    private fun extractMerchant(text: String, isWechat: Boolean): String? {
        // 尝试提取 "商户：xxx" 或 "收款方：xxx"
        val merchantPatterns = listOf(
            Pattern.compile("商户[：:]\\s*(.+)"),
            Pattern.compile("收款方[：:]\\s*(.+)"),
            Pattern.compile("付款给[：:]\\s*(.+)"),
            Pattern.compile("转账给[：:]\\s*(.+)"),
            Pattern.compile("向(.+)付款"),
            Pattern.compile("向(.+)转账"),
            Pattern.compile("交易商户[：:]\\s*(.+)"),
            Pattern.compile("消费商户[：:]\\s*(.+)"),
            Pattern.compile("对方[：:]\\s*(.+)"),
            Pattern.compile("收款人[：:]\\s*(.+)"),
        )

        for (pattern in merchantPatterns) {
            val matcher = pattern.matcher(text)
            if (matcher.find()) {
                val merchant = matcher.group(1)?.trim()
                if (!merchant.isNullOrEmpty() && merchant.length < 30) {
                    return merchant
                }
            }
        }

        return null
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
                "wechat" -> "微信"
                else -> "银行"
            }

            // 创建打开 app 并跳转到编辑页面的 Intent
            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
                putExtra("auto_record_payment", true)
                putExtra("auto_record_title", title)
                putExtra("auto_record_text", text)
                putExtra("auto_record_source", source)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            val pendingIntent = PendingIntent.getActivity(
                this, 0, launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val notification = NotificationCompat.Builder(this, "auto_record_payment")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle("🐻 检测到${sourceLabel}支付")
                .setContentText("$title $text · 点击打开记账")
                .setStyle(NotificationCompat.BigTextStyle().bigText("$title $text"))
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)
                .build()

            manager.notify(777, notification)
            Log.d(TAG, "已发送支付通知")
        } catch (e: Exception) {
            Log.e(TAG, "发送支付通知失败", e)
        }
    }

    /**
     * 通过 MethodChannel 推送给 Flutter
     */
    private fun pushToFlutter(amount: Double, merchant: String?, isWechat: Boolean, isAlipay: Boolean) {
        try {
            val engine = MainActivity.flutterEngine
            if (engine == null) {
                Log.w(TAG, "FlutterEngine 不可用，通知丢弃")
                return
            }

            val source = when {
                isWechat -> "wechat"
                isAlipay -> "alipay"
                else -> "bank"
            }
            val title = when {
                isWechat -> "微信支付"
                isAlipay -> "支付宝"
                else -> "银行支付"
            }

            val data = mapOf(
                "title" to title,
                "text" to buildString {
                    append("支付成功 ¥$amount")
                    if (!merchant.isNullOrEmpty()) append(" $merchant")
                },
                "source" to source,
                "timestamp" to System.currentTimeMillis(),
                "amount" to amount,
                "merchant" to (merchant ?: ""),
                "channel" to "accessibility"
            )

            MethodChannel(engine.dartExecutor.binaryMessenger, "bear_bill/auto_record")
                .invokeMethod("onPaymentNotification", data, null)

            Log.d(TAG, "已通过 MethodChannel 推送给 Flutter")
        } catch (e: Exception) {
            Log.e(TAG, "MethodChannel 推送失败", e)
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "无障碍服务被中断")
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "无障碍服务已销毁")
    }
}
