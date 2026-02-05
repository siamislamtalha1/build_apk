package com.musiclyco.musicly

import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.KeyEvent
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.session.MediaControllerCompat

class PlaybackWidgetActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return

        if (action == ACTION_REFRESH) {
            PlaybackWidgetProvider.updateAllWidgets(context)
            return
        }

        if (action == ACTION_LIKE) {
            // Use MediaControllerCompat to send a rating event to audio_service.
            // This is handled in Dart by overriding BaseAudioHandler.setRating.
            val browserRef = arrayOfNulls<MediaBrowserCompat>(1)
            val browser = MediaBrowserCompat(
                context,
                ComponentName(context, com.ryanheise.audioservice.AudioService::class.java),
                object : MediaBrowserCompat.ConnectionCallback() {
                    override fun onConnected() {
                        try {
                            val b = browserRef[0] ?: return
                            val controller = MediaControllerCompat(context, b.sessionToken)
                            controller.dispatchMediaButtonEvent(
                                KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_MEDIA_FAVORITE)
                            )
                        } catch (_: Exception) {
                        } finally {
                            try {
                                browserRef[0]?.disconnect()
                            } catch (_: Exception) {
                            }
                        }
                    }

                    override fun onConnectionFailed() {
                        try {
                            browserRef[0]?.disconnect()
                        } catch (_: Exception) {}
                    }
                },
                null
            )
            browserRef[0] = browser
            try {
                browser.connect()
            } catch (_: Exception) {}
            return
        }

        val keyCode = when (action) {
            ACTION_PREV -> KeyEvent.KEYCODE_MEDIA_PREVIOUS
            ACTION_PLAY_PAUSE -> KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
            ACTION_NEXT -> KeyEvent.KEYCODE_MEDIA_NEXT
            else -> return
        }

        val i = Intent(Intent.ACTION_MEDIA_BUTTON)
        i.setClassName(context, "com.ryanheise.audioservice.MediaButtonReceiver")
        i.putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
        context.sendBroadcast(i)
    }

    companion object {
        const val ACTION_PREV = "com.musiclyco.musicly.widget.PREV"
        const val ACTION_PLAY_PAUSE = "com.musiclyco.musicly.widget.PLAY_PAUSE"
        const val ACTION_NEXT = "com.musiclyco.musicly.widget.NEXT"
        const val ACTION_LIKE = "com.musiclyco.musicly.widget.LIKE"
        const val ACTION_REFRESH = "com.musiclyco.musicly.widget.REFRESH"
    }
}
