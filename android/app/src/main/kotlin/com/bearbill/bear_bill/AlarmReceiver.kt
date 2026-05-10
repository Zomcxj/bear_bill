package com.bearbill.bear_bill

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

class AlarmReceiver : BroadcastReceiver() {
    companion object {
        const val CHANNEL_ID = "daily_reminder"
        const val NOTIFICATION_ID = 0
    }

    override fun onReceive(context: Context, intent: Intent?) {
        // 检查今日是否已记账，已记账则跳过提醒
        val prefs = context.getSharedPreferences("alarm_prefs", Context.MODE_PRIVATE)
        val lastRecorded = prefs.getString("last_recorded_date", "") ?: ""
        val today = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.getDefault())
            .format(java.util.Date())
        if (lastRecorded == today) {
            // 已记账，仍需调度明天的闹钟
            val hour = prefs.getInt("reminder_hour", -1)
            val minute = prefs.getInt("reminder_minute", -1)
            if (hour >= 0 && minute >= 0) {
                AlarmScheduler.scheduleDaily(context, hour, minute)
            }
            return
        }

        // 创建通知渠道（确保存在）
        createNotificationChannel(context)

        // 点击通知打开 app
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pendingIntent = PendingIntent.getActivity(
            context, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 构建通知
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_notification)
            .setColor(0xFFFF8FAB.toInt())
            .setContentTitle("🐼 小熊记账提醒")
            .setContentText("今天还没记账哦，快来记录一笔吧～")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, notification)

        // 从 SharedPreferences 读取时间并重新调度明天的闹钟（每日重复）
        // 不依赖 intent extras，因为 FLAG_IMMUTABLE 会阻止 extras 更新
        val hour = prefs.getInt("reminder_hour", -1)
        val minute = prefs.getInt("reminder_minute", -1)
        if (hour >= 0 && minute >= 0) {
            AlarmScheduler.scheduleDaily(context, hour, minute)
        }
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
