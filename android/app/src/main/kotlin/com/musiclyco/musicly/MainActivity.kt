package com.musiclyco.musicly

import android.content.Intent
import android.media.audiofx.AudioEffect
import android.media.audiofx.LoudnessEnhancer
import android.media.audiofx.Visualizer
import android.os.Handler
import android.os.Looper
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val channelName = "com.musiclyco.musicly/audio_effects"
    private val visualizerChannelName = "com.musiclyco.musicly/visualizer"
    private var loudnessEnhancer: LoudnessEnhancer? = null
    private var loudnessSessionId: Int? = null

    private var visualizer: Visualizer? = null
    private var visualizerSessionId: Int? = null
    private var visualizerEnabled: Boolean = false
    private var visualizerSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, visualizerChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    visualizerSink = events
                    maybeStartVisualizer()
                }

                override fun onCancel(arguments: Any?) {
                    visualizerSink = null
                    stopVisualizer()
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openEqualizer" -> {
                        val sessionId = call.argument<Int>("sessionId")
                        if (sessionId == null) {
                            result.success(false)
                            return@setMethodCallHandler
                        }

                        try {
                            val intent = Intent(AudioEffect.ACTION_DISPLAY_AUDIO_EFFECT_CONTROL_PANEL)
                            intent.putExtra(AudioEffect.EXTRA_AUDIO_SESSION, sessionId)
                            intent.putExtra(AudioEffect.EXTRA_PACKAGE_NAME, packageName)
                            intent.putExtra(AudioEffect.EXTRA_CONTENT_TYPE, AudioEffect.CONTENT_TYPE_MUSIC)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

                            val canHandle = intent.resolveActivity(packageManager) != null
                            if (canHandle) {
                                startActivity(intent)
                            }
                            result.success(canHandle)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }

                    "setNormalization" -> {
                        val sessionId = call.argument<Int>("sessionId")
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        val gainMb = call.argument<Int>("gainMb") ?: 0

                        if (sessionId == null) {
                            result.success(false)
                            return@setMethodCallHandler
                        }

                        try {
                            if (loudnessEnhancer == null || loudnessSessionId != sessionId) {
                                loudnessEnhancer?.release()
                                loudnessEnhancer = LoudnessEnhancer(sessionId)
                                loudnessSessionId = sessionId
                            }

                            loudnessEnhancer?.setTargetGain(gainMb.coerceIn(0, 2000))
                            loudnessEnhancer?.enabled = enabled
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }

                    "setVisualizer" -> {
                        val sessionId = call.argument<Int>("sessionId")
                        val enabled = call.argument<Boolean>("enabled") ?: false

                        visualizerEnabled = enabled
                        visualizerSessionId = sessionId
                        if (enabled) {
                            maybeStartVisualizer()
                        } else {
                            stopVisualizer()
                        }
                        result.success(true)
                    }

                    "updateWidget" -> {
                        val title = call.argument<String>("title") ?: ""
                        val artist = call.argument<String>("artist") ?: ""
                        val isPlaying = call.argument<Boolean>("isPlaying") ?: false

                        try {
                            val prefs = getSharedPreferences("playback_widget", MODE_PRIVATE)
                            prefs.edit()
                                .putString("title", title)
                                .putString("artist", artist)
                                .putBoolean("isPlaying", isPlaying)
                                .apply()

                            val mgr = AppWidgetManager.getInstance(this)
                            val ids = mgr.getAppWidgetIds(
                                ComponentName(this, PlaybackWidgetProvider::class.java)
                            )
                            if (ids.isNotEmpty()) {
                                PlaybackWidgetProvider.updateAllWidgets(this)
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun maybeStartVisualizer() {
        if (!visualizerEnabled) return
        val sink = visualizerSink ?: return
        val sessionId = visualizerSessionId ?: return

        try {
            if (visualizer != null && sessionId == visualizer?.audioSessionId) {
                return
            }

            stopVisualizer()

            val v = Visualizer(sessionId)
            val range = Visualizer.getCaptureSizeRange()
            v.captureSize = range[1]
            v.setDataCaptureListener(
                object : Visualizer.OnDataCaptureListener {
                    override fun onWaveFormDataCapture(
                        visualizer: Visualizer,
                        waveform: ByteArray,
                        samplingRate: Int
                    ) {
                        mainHandler.post {
                            try {
                                sink.success(waveform)
                            } catch (_: Exception) {
                            }
                        }
                    }

                    override fun onFftDataCapture(
                        visualizer: Visualizer,
                        fft: ByteArray,
                        samplingRate: Int
                    ) {
                    }
                },
                Visualizer.getMaxCaptureRate() / 2,
                true,
                false
            )
            v.enabled = true

            visualizer = v
        } catch (_: Exception) {
            stopVisualizer()
        }
    }

    private fun stopVisualizer() {
        try {
            visualizer?.enabled = false
        } catch (_: Exception) {
        }
        try {
            visualizer?.release()
        } catch (_: Exception) {
        }
        visualizer = null
    }
}
