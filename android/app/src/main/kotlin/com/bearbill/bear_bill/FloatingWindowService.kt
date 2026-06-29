package com.bearbill.bear_bill

import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.*
import io.flutter.plugin.common.MethodChannel

/**
 * 悬浮窗服务 - 用于自动记账确认
 */
class FloatingWindowService : Service() {

    companion object {
        private const val TAG = "FloatingWindow"
        private var instance: FloatingWindowService? = null

        fun showPaymentConfirmation(
            context: Context,
            amount: Double,
            source: String,
            title: String,
            text: String
        ) {
            val intent = Intent(context, FloatingWindowService::class.java).apply {
                putExtra("amount", amount)
                putExtra("source", source)
                putExtra("title", title)
                putExtra("text", text)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startService(intent)
        }

        fun isRunning(): Boolean = instance != null
    }

    private var windowManager: WindowManager? = null
    private var floatingView: View? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        Log.d(TAG, "悬浮窗服务已创建")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val amount = intent?.getDoubleExtra("amount", 0.0) ?: 0.0
        val source = intent?.getStringExtra("source") ?: "unknown"
        val title = intent?.getStringExtra("title") ?: ""
        val text = intent?.getStringExtra("text") ?: ""

        Log.d(TAG, "悬浮窗服务收到命令: amount=$amount, source=$source, title=$title")

        if (amount > 0) {
            showFloatingWindow(amount, source, title, text)
        } else {
            Log.w(TAG, "金额为0，不显示悬浮窗")
        }

        return START_NOT_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        removeFloatingWindow()
        instance = null
        Log.d(TAG, "悬浮窗服务已销毁")
    }

    private fun showFloatingWindow(amount: Double, source: String, title: String, text: String) {
        // 检查悬浮窗权限
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            Log.e(TAG, "没有悬浮窗权限！请在设置中开启")
            // 如果没有权限，回退到通知方式
            val notificationManager = getSystemService(NOTIFICATION_SERVICE) as android.app.NotificationManager
            val channel = android.app.NotificationChannel(
                "auto_record_fallback",
                "自动记账",
                android.app.NotificationManager.IMPORTANCE_HIGH
            )
            notificationManager.createNotificationChannel(channel)
            val notification = androidx.core.app.NotificationCompat.Builder(this, "auto_record_fallback")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle("🐻 检测到支付")
                .setContentText("¥$amount - 请开启悬浮窗权限以使用确认功能")
                .setPriority(androidx.core.app.NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .build()
            notificationManager.notify(778, notification)
            return
        }

        // 移除旧的悬浮窗
        removeFloatingWindow()

        try {
            // 创建悬浮窗布局
            floatingView = createFloatingView(amount, source, title, text)

            // 设置窗口参数（允许触摸穿透到后面的窗口）
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                else
                    WindowManager.LayoutParams.TYPE_PHONE,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
                y = 100
            }

            windowManager?.addView(floatingView, params)
            Log.d(TAG, "悬浮窗已显示: ¥$amount")
        } catch (e: Exception) {
            Log.e(TAG, "显示悬浮窗失败", e)
            // 如果悬浮窗失败，回退到通知方式
            val notificationManager = getSystemService(NOTIFICATION_SERVICE) as android.app.NotificationManager
            val channel = android.app.NotificationChannel(
                "auto_record_fallback",
                "自动记账",
                android.app.NotificationManager.IMPORTANCE_HIGH
            )
            notificationManager.createNotificationChannel(channel)
            val notification = androidx.core.app.NotificationCompat.Builder(this, "auto_record_fallback")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle("🐻 检测到支付")
                .setContentText("¥$amount - 悬浮窗显示失败")
                .setPriority(androidx.core.app.NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .build()
            notificationManager.notify(778, notification)
        }
    }

    private fun createFloatingView(amount: Double, source: String, title: String, text: String): View {
        // 使用代码创建悬浮窗布局（更可靠）
        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(0xFFFFFFFF.toInt())
            setPadding(32, 24, 32, 24)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }

        // 标题
        val titleText = TextView(this).apply {
            this.text = "🐻 自动记账"
            textSize = 18f
            setTextColor(0xFF333333.toInt())
            setTypeface(null, android.graphics.Typeface.BOLD)
        }
        container.addView(titleText)

        // 金额
        val amountText = TextView(this).apply {
            this.text = "¥${String.format("%.2f", amount)}"
            textSize = 28f
            setTextColor(0xFFFF6B6B.toInt())
            setTypeface(null, android.graphics.Typeface.BOLD)
            setPadding(0, 16, 0, 8)
        }
        container.addView(amountText)

        // 来源
        val sourceLabel = when (source) {
            "alipay" -> "支付宝"
            "wechat" -> "微信"
            else -> "银行"
        }
        val sourceText = TextView(this).apply {
            this.text = "来源: $sourceLabel"
            textSize = 14f
            setTextColor(0xFF666666.toInt())
        }
        container.addView(sourceText)

        // 分隔线
        val divider = View(this).apply {
            setBackgroundColor(0xFFE0E0E0.toInt())
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, 2
            ).apply { topMargin = 16; bottomMargin = 16 }
        }
        container.addView(divider)

        // 分类选择
        val categoryLabel = TextView(this).apply {
            this.text = "分类:"
            textSize = 14f
            setTextColor(0xFF333333.toInt())
        }
        container.addView(categoryLabel)

        val categories = arrayOf("餐饮", "交通", "购物", "娱乐", "医疗", "教育", "其他")
        val categorySpinner = Spinner(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { topMargin = 8; bottomMargin = 12 }
        }
        val adapter = ArrayAdapter(this, android.R.layout.simple_spinner_item, categories)
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        categorySpinner.adapter = adapter
        container.addView(categorySpinner)

        // 备注
        val remarkEdit = EditText(this).apply {
            hint = "备注（可选）"
            textSize = 14f
            setPadding(16, 12, 16, 12)
            setBackgroundResource(android.R.drawable.edit_text)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = 16 }
        }
        container.addView(remarkEdit)

        // 按钮行
        val buttonRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = android.view.Gravity.CENTER
        }

        val cancelButton = Button(this).apply {
            setText("取消")
            textSize = 14f
            setTextColor(0xFF666666.toInt())
            layoutParams = LinearLayout.LayoutParams(0, 120, 1f).apply { marginEnd = 16 }
            setOnClickListener {
                removeFloatingWindow()
                stopSelf()
            }
        }
        buttonRow.addView(cancelButton)

        val confirmButton = Button(this).apply {
            setText("确认记账")
            textSize = 14f
            setTextColor(0xFFFFFFFF.toInt())
            setBackgroundColor(0xFFFF6B6B.toInt())
            layoutParams = LinearLayout.LayoutParams(0, 120, 1f).apply { marginStart = 16 }
            setOnClickListener {
                val category = categorySpinner.selectedItem.toString()
                val remark = remarkEdit.text.toString().ifEmpty { "自动记账" }
                saveRecord(amount, source, category, remark)
                removeFloatingWindow()
                stopSelf()
            }
        }
        buttonRow.addView(confirmButton)

        container.addView(buttonRow)

        // 设置拖拽
        setupDrag(container)

        return container
    }

    private fun saveRecord(amount: Double, source: String, category: String, remark: String) {
        try {
            val engine = MainActivity.flutterEngine
            if (engine != null) {
                val data = mapOf(
                    "amount" to amount,
                    "source" to source,
                    "category" to category,
                    "remark" to remark,
                    "timestamp" to System.currentTimeMillis()
                )
                MethodChannel(engine.dartExecutor.binaryMessenger, "bear_bill/auto_record")
                    .invokeMethod("saveAutoRecord", data)
                Log.d(TAG, "已推送保存请求: ¥$amount $category")
            } else {
                // Flutter 引擎不可用，存到 SharedPreferences
                val prefs = getSharedPreferences("auto_record_prefs", MODE_PRIVATE)
                prefs.edit()
                    .putFloat("pending_save_amount", amount.toFloat())
                    .putString("pending_save_source", source)
                    .putString("pending_save_category", category)
                    .putString("pending_save_remark", remark)
                    .putLong("pending_save_timestamp", System.currentTimeMillis())
                    .apply()
                Log.d(TAG, "Flutter 引擎不可用，数据已存到 SharedPreferences")
            }
        } catch (e: Exception) {
            Log.e(TAG, "保存记录失败", e)
        }
    }

    private fun setupDrag(view: View) {
        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f

        view.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    val params = view.layoutParams as WindowManager.LayoutParams
                    initialX = params.x
                    initialY = params.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val params = view.layoutParams as WindowManager.LayoutParams
                    params.x = initialX + (event.rawX - initialTouchX).toInt()
                    params.y = initialY + (event.rawY - initialTouchY).toInt()
                    windowManager?.updateViewLayout(view, params)
                    true
                }
                else -> false
            }
        }
    }

    private fun removeFloatingWindow() {
        try {
            if (floatingView != null) {
                windowManager?.removeView(floatingView)
                floatingView = null
            }
        } catch (e: Exception) {
            Log.e(TAG, "移除悬浮窗失败", e)
        }
    }
}
