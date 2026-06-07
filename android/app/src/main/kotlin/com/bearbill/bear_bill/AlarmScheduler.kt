package com.bearbill.bear_bill

import android.app.AlarmManager
import android.app.NotificationManager
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
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 同一天内多次改时间时，先清掉旧闹钟，避免残留多个计划任务。
        alarmManager.cancel(pendingIntent)

        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (timeInMillis <= System.currentTimeMillis()) {
                add(Calendar.DAY_OF_YEAR, 1)
            }
        }

        val showIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val showPendingIntent = PendingIntent.getActivity(
            context,
            0,
            showIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        alarmManager.setAlarmClock(
            AlarmManager.AlarmClockInfo(calendar.timeInMillis, showPendingIntent),
            pendingIntent
        )
    }

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
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)

        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(AlarmReceiver.NOTIFICATION_ID)
    }
}
