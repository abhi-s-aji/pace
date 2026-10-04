package com.pace.app.pace

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class StreakWidgetReceiver : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.streak_widget)

            val streak = widgetData.getInt("current_streak", 0)
            val remaining = widgetData.getInt("remaining_habits", 0)

            views.setTextViewText(R.id.streak_text, "🔥 $streak Day Streak")
            val remText = if (remaining == 1) "1 habit remaining today" else "$remaining habits remaining today"
            views.setTextViewText(R.id.reminder_subtext, remText)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
