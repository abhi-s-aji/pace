package com.pace.app.pace

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class TodayProgressWidgetReceiver : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.today_progress_widget)

            val completed = widgetData.getInt("today_completed", 0)
            val total = widgetData.getInt("today_total", 0)
            val percent = widgetData.getInt("today_progress", 0)

            views.setTextViewText(R.id.widget_status, "$completed / $total habits")

            val filledBlocks = (percent / 10).coerceIn(0, 10)
            val emptyBlocks = 10 - filledBlocks
            val bar = "█".repeat(filledBlocks) + "░".repeat(emptyBlocks) + " $percent%"
            views.setTextViewText(R.id.widget_progress_bar, bar)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
