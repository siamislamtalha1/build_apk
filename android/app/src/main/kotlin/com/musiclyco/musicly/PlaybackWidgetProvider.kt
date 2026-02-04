package com.musiclyco.musicly

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.view.KeyEvent
import android.widget.RemoteViews

class PlaybackWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            updateAllWidgets(context)
        }
    }

    companion object {
        private const val PREFS_NAME = "playback_widget"

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, PlaybackWidgetProvider::class.java)
            )
            for (id in ids) {
                updateAppWidget(context, manager, id)
            }
        }

        private fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val title = prefs.getString("title", "") ?: ""
            val artist = prefs.getString("artist", "") ?: ""
            val isPlaying = prefs.getBoolean("isPlaying", false)

            val views = RemoteViews(context.packageName, R.layout.playback_widget)
            views.setTextViewText(R.id.widget_title, title.ifEmpty { "Musicly" })
            views.setTextViewText(R.id.widget_artist, artist)

            val playPauseIcon = if (isPlaying) {
                android.R.drawable.ic_media_pause
            } else {
                android.R.drawable.ic_media_play
            }
            views.setImageViewResource(R.id.widget_play_pause, playPauseIcon)

            views.setOnClickPendingIntent(
                R.id.widget_prev,
                mediaButtonPendingIntent(context, KeyEvent.KEYCODE_MEDIA_PREVIOUS, 1)
            )
            views.setOnClickPendingIntent(
                R.id.widget_play_pause,
                mediaButtonPendingIntent(context, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE, 2)
            )
            views.setOnClickPendingIntent(
                R.id.widget_next,
                mediaButtonPendingIntent(context, KeyEvent.KEYCODE_MEDIA_NEXT, 3)
            )

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun mediaButtonPendingIntent(
            context: Context,
            keyCode: Int,
            requestCode: Int
        ): PendingIntent {
            val intent = Intent(Intent.ACTION_MEDIA_BUTTON)
            intent.setClassName(context, "com.ryanheise.audioservice.MediaButtonReceiver")
            intent.putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_DOWN, keyCode))

            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }

            return PendingIntent.getBroadcast(context, requestCode, intent, flags)
        }
    }
}
