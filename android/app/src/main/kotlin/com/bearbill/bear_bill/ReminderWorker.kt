package com.bearbill.bear_bill

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

class ReminderWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        val prefs = applicationContext.getSharedPreferences("alarm_prefs", Context.MODE_PRIVATE)
        val hour = prefs.getInt("reminder_hour", -1)
        val minute = prefs.getInt("reminder_minute", -1)
        if (hour < 0 || minute < 0) return Result.success()

        val today = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        val lastFireDate = prefs.getString("last_fire_date", "") ?: ""

        // 今天的提醒已触发过，跳过
        if (lastFireDate == today) return Result.success()

        // 还没到提醒时间，跳过
        val now = Calendar.getInstance()
        val targetMinute = hour * 60 + minute
        val currentMinute = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        if (currentMinute < targetMinute) return Result.success()

        // 补发通知
        postNotification(prefs)

        // 记录已触发
        prefs.edit().putString("last_fire_date", today).apply()

        // 确保明天的 AlarmManager 闹钟还在
        AlarmScheduler.ensureScheduled(applicationContext)

        return Result.success()
    }

    private fun postNotification(prefs: android.content.SharedPreferences) {
        createNotificationChannel()

        val launchIntent = applicationContext.packageManager
            .getLaunchIntentForPackage(applicationContext.packageName)
        val pendingIntent = PendingIntent.getActivity(
            applicationContext, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val today = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        val summaryDate = prefs.getString("summary_date", "") ?: ""
        val count = prefs.getInt("today_count", 0)
        val expense = prefs.getFloat("today_expense", 0f)
        val income = prefs.getFloat("today_income", 0f)

        val title: String
        val content: String

        if (summaryDate == today && count > 0) {
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
            title = "🐼 记账提醒"
            content = "今天还没记账哦，快来记录一笔吧～"
        }

        val notification = NotificationCompat.Builder(applicationContext, CHANNEL_ID)
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

        val manager = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, notification)
    }

    private fun createNotificationChannel() {
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
            val manager = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    companion object {
        const val CHANNEL_ID = "daily_reminder"
        const val NOTIFICATION_ID = 0
    }
}
