package com.pace.app.pace

import android.appwidget.AppWidgetManager
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class HabitActionWidgetReceiver : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.habit_action_widget)

            val habitId = widgetData.getString("quick_habit_id", "") ?: ""
            val habitName = widgetData.getString("quick_habit_name", "No habits scheduled") ?: "No habits scheduled"
            val isCompleted = widgetData.getBoolean("quick_habit_completed", false)

            views.setTextViewText(R.id.habit_name, habitName)

            if (habitId.isNotEmpty() && !isCompleted) {
                views.setTextViewText(R.id.btn_complete, "Mark Complete")
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("pace://complete_habit?id=$habitId")
                )
                views.setOnClickPendingIntent(R.id.btn_complete, pendingIntent)
            } else if (isCompleted && habitId.isNotEmpty()) {
                views.setTextViewText(R.id.btn_complete, "✓ Completed Today")
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("pace://open")
                )
                views.setOnClickPendingIntent(R.id.btn_complete, pendingIntent)
            } else {
                views.setTextViewText(R.id.btn_complete, "Open Pace")
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("pace://open")
                )
                views.setOnClickPendingIntent(R.id.btn_complete, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
