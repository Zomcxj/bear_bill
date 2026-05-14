package com.bearbill.bear_bill

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import androidx.core.app.NotificationCompat

class AlarmReceiver : BroadcastReceiver() {
    companion object {
        const val CHANNEL_ID = "daily_reminder"
        const val NOTIFICATION_ID = 0
    }

    override fun onReceive(context: Context, intent: Intent?) {
        // WakeLock 防止 CPU 休眠导致重新调度失败
        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "bear_bill:alarm")
        wakeLock.acquire(10_000L)

        val prefs = context.getSharedPreferences("alarm_prefs", Context.MODE_PRIVATE)

        // 创建通知渠道（确保存在）
        createNotificationChannel(context)

        // 点击通知打开 app
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pendingIntent = PendingIntent.getActivity(
            context, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 读取今日记账数据
        val today = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.getDefault())
            .format(java.util.Date())
        val summaryDate = prefs.getString("summary_date", "") ?: ""
        val count = prefs.getInt("today_count", 0)
        val expense = prefs.getFloat("today_expense", 0f)
        val income = prefs.getFloat("today_income", 0f)

        val title: String
        val content: String

        if (summaryDate == today && count > 0) {
            // 今日已记账 → 总结
            title = "🐼 今日记账总结"
            val parts = mutableListOf<String>()
            parts.add("${count}笔记录")
            if (expense > 0) parts.add("支出¥${"%.0f".format(expense)}")
            if (income > 0) parts.add("收入¥${"%.0f".format(income)}")
            val suffix = when {
                expense >= 5000 -> "简直壕气！💰"
                expense >= 1000 -> "太有实力了！💪"
                expense >= 500 -> "花得不少呢～😅"
                expense > 0 -> "继续保持～"
                else -> "今天没有支出，攒钱达人！🌟"
            }
            content = parts.joinToString("，") + "。$suffix"
        } else {
            // 今日未记账 → 提醒
            title = "🐼 记账提醒"
            content = "今天还没记账哦，快来记录一笔吧～"
        }

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_notification)
            .setColor(0xFFFF8FAB.toInt())
            .setContentTitle(title)
            .setContentText(content)
            .setStyle(NotificationCompat.BigTextStyle().bigText(content))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, notification)

        // 重新调度明天的闹钟（每日重复）
        val hour = prefs.getInt("reminder_hour", -1)
        val minute = prefs.getInt("reminder_minute", -1)
        if (hour >= 0 && minute >= 0) {
            AlarmScheduler.scheduleDaily(context, hour, minute)
        }

        wakeLock.release()
    }

    private fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "每日记账提醒",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "提醒你每天记录账单"
                enableVibration(true)
                enableLights(true)
            }
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }
}
