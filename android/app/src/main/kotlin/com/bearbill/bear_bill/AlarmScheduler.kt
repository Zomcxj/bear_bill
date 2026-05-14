package com.bearbill.bear_bill

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import java.util.Calendar

object AlarmScheduler {
    private const val REQUEST_CODE = 1001

    fun scheduleDaily(context: Context, hour: Int, minute: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val intent = Intent(context, AlarmReceiver::class.java)

        val pendingIntent = PendingIntent.getBroadcast(
            context, REQUEST_CODE, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 计算下次提醒时间
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (timeInMillis <= System.currentTimeMillis()) {
                add(Calendar.DAY_OF_YEAR, 1)
            }
        }

        // 使用 setAlarmClock — Android 将其视为用户可见的闹钟
        // 不受 Doze 模式和省电策略影响，所有 ROM 均可靠触发
        val showIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val showPendingIntent = PendingIntent.getActivity(
            context, 0, showIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.setAlarmClock(
            AlarmManager.AlarmClockInfo(calendar.timeInMillis, showPendingIntent),
            pendingIntent
        )
    }

    /// 检查闹钟是否已设置，未设置则重新调度
    fun ensureScheduled(context: Context) {
        val prefs = context.getSharedPreferences("alarm_prefs", Context.MODE_PRIVATE)
        val hour = prefs.getInt("reminder_hour", -1)
        val minute = prefs.getInt("reminder_minute", -1)
        if (hour >= 0 && minute >= 0) {
            scheduleDaily(context, hour, minute)
        }
    }

    fun cancel(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context, REQUEST_CODE, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
    }
}
