package dts.musiclyco.musicly

import android.app.PendingIntent
import android.app.AlarmManager
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Bundle
import android.view.KeyEvent
import android.widget.RemoteViews
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest

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

        if (intent.action == PlaybackWidgetActionReceiver.ACTION_REFRESH) {
            updateAllWidgets(context)

            // Keep ticking while playing
            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val isPlaying = prefs.getBoolean("isPlaying", false)
                setAutoRefresh(context, isPlaying)
            } catch (_: Exception) {}
        }
    }

    companion object {
        private const val PREFS_NAME = "playback_widget"

        private fun getLayoutId(options: Bundle?): Int {
            val minW = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH) ?: 0
            val minH = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT) ?: 0

            // Height-based heuristics (dp). Launcher reports approx.
            return when {
                minH >= 220 -> R.layout.playback_widget_xl
                minH >= 160 -> R.layout.playback_widget_large
                minH >= 110 -> R.layout.playback_widget_medium
                else -> R.layout.playback_widget_small
            }
        }

        private fun actionPendingIntent(
            context: Context,
            action: String,
            requestCode: Int
        ): PendingIntent {
            val intent = Intent(context, PlaybackWidgetActionReceiver::class.java)
            intent.action = action

            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }

            return PendingIntent.getBroadcast(context, requestCode, intent, flags)
        }

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
            val artUrl = prefs.getString("artUrl", "") ?: ""
            val source = prefs.getString("source", "") ?: ""
            val positionMs = prefs.getLong("positionMs", 0L)
            val positionAtUpdateMs = prefs.getLong("positionAtUpdateMs", positionMs)
            val lastUpdatedAtMs = prefs.getLong("lastUpdatedAtMs", 0L)
            val durationMs = prefs.getLong("durationMs", 0L)
            val isLiked = prefs.getBoolean("isLiked", false)

            val effectivePositionMs = try {
                if (!isPlaying || lastUpdatedAtMs <= 0L) {
                    positionMs
                } else {
                    val drift = (System.currentTimeMillis() - lastUpdatedAtMs).coerceAtLeast(0L)
                    (positionAtUpdateMs + drift).coerceAtMost(durationMs)
                }
            } catch (_: Exception) {
                positionMs
            }

            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val layoutId = getLayoutId(options)

            val views = RemoteViews(context.packageName, layoutId)
            views.setTextViewText(R.id.widget_title, title.ifEmpty { "Musicly" })

            // Tap anywhere to open app
            try {
                val openIntent = Intent(context, MainActivity::class.java)
                openIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                val openFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                val openPi = PendingIntent.getActivity(context, 99, openIntent, openFlags)
                views.setOnClickPendingIntent(R.id.widget_root, openPi)
            } catch (_: Exception) {}

            try {
                views.setTextViewText(R.id.widget_artist, artist)
            } catch (_: Exception) {}

            try {
                views.setTextViewText(R.id.widget_source, source)
            } catch (_: Exception) {}

            // Artwork (async)
            try {
                if (artUrl.isNotEmpty()) {
                    Thread {
                        val bmp = tryLoadBitmap(context, artUrl)
                        if (bmp != null) {
                            try {
                                val v2 = RemoteViews(context.packageName, layoutId)
                                // Copy minimal required fields for image update
                                v2.setImageViewBitmap(R.id.widget_art, bmp)
                                appWidgetManager.partiallyUpdateAppWidget(appWidgetId, v2)
                            } catch (_: Exception) {
                            }
                        }
                    }.start()
                }
            } catch (_: Exception) {}

            val playPauseIcon = if (isPlaying) {
                android.R.drawable.ic_media_pause
            } else {
                android.R.drawable.ic_media_play
            }
            views.setImageViewResource(R.id.widget_play_pause, playPauseIcon)

            // Progress is 0..1000
            try {
                val progress = if (durationMs > 0L) {
                    ((effectivePositionMs.toDouble() / durationMs.toDouble()) * 1000.0).toInt()
                        .coerceIn(0, 1000)
                } else 0
                views.setProgressBar(R.id.widget_progress, 1000, progress, false)
            } catch (_: Exception) {}

            // Like icon
            try {
                val likeIcon = if (isLiked) {
                    android.R.drawable.btn_star_big_on
                } else {
                    android.R.drawable.btn_star_big_off
                }
                views.setImageViewResource(R.id.widget_like, likeIcon)
            } catch (_: Exception) {}

            views.setOnClickPendingIntent(
                R.id.widget_prev,
                actionPendingIntent(context, PlaybackWidgetActionReceiver.ACTION_PREV, 1)
            )
            views.setOnClickPendingIntent(
                R.id.widget_play_pause,
                actionPendingIntent(context, PlaybackWidgetActionReceiver.ACTION_PLAY_PAUSE, 2)
            )
            views.setOnClickPendingIntent(
                R.id.widget_next,
                actionPendingIntent(context, PlaybackWidgetActionReceiver.ACTION_NEXT, 3)
            )

            try {
                views.setOnClickPendingIntent(
                    R.id.widget_like,
                    actionPendingIntent(context, PlaybackWidgetActionReceiver.ACTION_LIKE, 4)
                )
            } catch (_: Exception) {}

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun tryLoadBitmap(context: Context, url: String): Bitmap? {
            val cached = tryLoadCachedBitmap(context, url)
            if (cached != null) return cached

            val downloaded = tryLoadBitmapFromUrl(url) ?: return null
            tryWriteCachedBitmap(context, url, downloaded)
            return downloaded
        }

        private fun cacheDir(context: Context): File {
            val d = File(context.cacheDir, "widget_art")
            if (!d.exists()) {
                try {
                    d.mkdirs()
                } catch (_: Exception) {}
            }
            return d
        }

        private fun cacheFileForUrl(context: Context, url: String): File {
            val md = MessageDigest.getInstance("MD5")
            val hash = md.digest(url.toByteArray()).joinToString("") { "%02x".format(it) }
            return File(cacheDir(context), "$hash.png")
        }

        private fun tryLoadCachedBitmap(context: Context, url: String): Bitmap? {
            return try {
                val f = cacheFileForUrl(context, url)
                if (!f.exists()) return null

                // 7 days cache TTL
                val ageMs = System.currentTimeMillis() - f.lastModified()
                if (ageMs > 7L * 24L * 60L * 60L * 1000L) {
                    try {
                        f.delete()
                    } catch (_: Exception) {}
                    return null
                }
                BitmapFactory.decodeFile(f.absolutePath)
            } catch (_: Exception) {
                null
            }
        }

        private fun tryWriteCachedBitmap(context: Context, url: String, bmp: Bitmap) {
            try {
                val f = cacheFileForUrl(context, url)
                FileOutputStream(f).use { out ->
                    bmp.compress(Bitmap.CompressFormat.PNG, 90, out)
                    out.flush()
                }
            } catch (_: Exception) {
            }
        }

        private fun tryLoadBitmapFromUrl(url: String): Bitmap? {
            try {
                val u = URL(url)
                val conn = (u.openConnection() as HttpURLConnection)
                conn.connectTimeout = 4000
                conn.readTimeout = 4000
                conn.instanceFollowRedirects = true
                conn.doInput = true
                conn.connect()
                conn.inputStream.use { stream ->
                    val bmp = BitmapFactory.decodeStream(stream) ?: return null
                    return downscale(bmp)
                }
            } catch (_: Exception) {
                return null
            }
        }

        private fun downscale(bmp: Bitmap): Bitmap {
            val max = 256
            val w = bmp.width
            val h = bmp.height
            val scale = maxOf(w, h).toFloat() / max.toFloat()
            return if (scale > 1f) {
                Bitmap.createScaledBitmap(
                    bmp,
                    (w / scale).toInt().coerceAtLeast(1),
                    (h / scale).toInt().coerceAtLeast(1),
                    true
                )
            } else bmp
        }

        fun setAutoRefresh(context: Context, isPlaying: Boolean) {
            val alarm = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                ?: return

            val intent = Intent(context, PlaybackWidgetActionReceiver::class.java)
            intent.action = PlaybackWidgetActionReceiver.ACTION_REFRESH

            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val pi = PendingIntent.getBroadcast(context, 77, intent, flags)

            if (!isPlaying) {
                try {
                    alarm.cancel(pi)
                } catch (_: Exception) {}
                return
            }

            val intervalMs = 2000L
            val triggerAt = System.currentTimeMillis() + intervalMs
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarm.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
                } else {
                    alarm.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pi)
                }
            } catch (_: Exception) {
            }
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
