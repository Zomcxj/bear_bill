package com.bearbill.bear_bill

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import io.flutter.plugin.common.MethodChannel
import java.util.regex.Pattern

/**
 * 支付无障碍服务 - 监听微信/支付宝支付成功页面，自动提取金额
 */
class PaymentAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "AutoRecord_A11y"
        private const val COOLDOWN_MS = 10000L // 10秒内不重复处理同一笔

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

        // 金额匹配模式
        val AMOUNT_PATTERNS = listOf(
            Pattern.compile("[¥￥]\\s*(\\d+\\.?\\d{0,2})"),
            Pattern.compile("(\\d+\\.\\d{2})\\s*元"),
            Pattern.compile("金额\\s*[¥￥]?\\s*(\\d+\\.?\\d{0,2})"),
        )
    }

    private var lastProcessedTime = 0L
    private var lastProcessedText = ""

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "无障碍服务已连接")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        // 不在这里检查 auto_record_prefs 开关（跨进程 SharedPreferences 隔离，读不到）
        // 始终检测支付事件，由 Flutter 端决定是否处理

        val packageName = event.packageName?.toString() ?: return
        if (packageName !in listOf("com.tencent.mm", "com.eg.android.AlipayGphone")) return

        // 只处理窗口变化事件
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
            event.eventType != AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) return

        try {
            val rootNode = rootInActiveWindow ?: return
            val screenText = extractAllText(rootNode)

            if (screenText.length < 5) return

            // 冷却检查：避免同一笔支付重复触发
            val now = System.currentTimeMillis()
            if (now - lastProcessedTime < COOLDOWN_MS && screenText == lastProcessedText) return

            val isWechat = packageName.contains("tencent")
            val keywords = if (isWechat) WECHAT_SUCCESS_KEYWORDS else ALIPAY_SUCCESS_KEYWORDS
            val isPaymentSuccess = keywords.any { screenText.contains(it) }

            if (!isPaymentSuccess) return

            // 提取金额
            val amount = extractAmount(screenText)
            if (amount == null || amount <= 0) return

            // 提取商户/描述
            val merchant = extractMerchant(screenText, isWechat)

            Log.d(TAG, "检测到支付成功: ¥$amount $merchant")

            lastProcessedTime = now
            lastProcessedText = screenText

            // 通过 MethodChannel 推送给 Flutter
            pushToFlutter(amount, merchant, isWechat)

        } catch (e: Exception) {
            Log.e(TAG, "处理无障碍事件失败", e)
        }
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

    /**
     * 通过 MethodChannel 推送给 Flutter
     */
    private fun pushToFlutter(amount: Double, merchant: String?, isWechat: Boolean) {
        try {
            val engine = MainActivity.flutterEngine
            if (engine == null) {
                Log.w(TAG, "FlutterEngine 不可用，通知丢弃")
                return
            }

            val data = mapOf(
                "title" to if (isWechat) "微信支付" else "支付宝",
                "text" to buildString {
                    append("支付成功 ¥$amount")
                    if (!merchant.isNullOrEmpty()) append(" $merchant")
                },
                "source" to if (isWechat) "wechat" else "alipay",
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
