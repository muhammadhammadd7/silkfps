package com.silkfps.silkfps

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.hardware.display.DisplayManager
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.Display

class SilkfpsPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var activity: Activity? = null
    private var context: Context? = null

    private var targetRefreshRate: Float = 0f
    private var displayManager: DisplayManager? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    // EventChannel sink — sends Hz updates to Dart
    private var eventSink: EventChannel.EventSink? = null

    companion object {
        private const val TAG = "SilkFPS"
        private const val MIN_SUPPORTED_API = Build.VERSION_CODES.R // API 30
        private const val API_SKIA_MAX = Build.VERSION_CODES.S_V2   // API 32
        private const val API_IMPELLER_MIN = Build.VERSION_CODES.TIRAMISU // API 33
    }

    // ─────────────────────────────────────────────────────────
    // DisplayListener — fires instantly when OS changes Hz
    // Also pushes to EventChannel → Dart gets real-time updates
    // ─────────────────────────────────────────────────────────
    private val displayListener = object : DisplayManager.DisplayListener {
        override fun onDisplayChanged(displayId: Int) {
            if (displayId != Display.DEFAULT_DISPLAY) return
            val act = activity ?: return

            val currentRate = act.windowManager.defaultDisplay.mode.refreshRate

            // Push real-time Hz to Dart via EventChannel
            mainHandler.post {
                eventSink?.success(currentRate.toDouble())
            }

            // Re-apply if OS overrode our target
            if (targetRefreshRate > 0f && currentRate < targetRefreshRate - 1f) {
                android.util.Log.w(TAG, "DisplayListener: OS changed to ${currentRate}Hz → re-applying ${targetRefreshRate}Hz")
                mainHandler.post { applyPreferredMode(act, targetRefreshRate) }
            }
        }
        override fun onDisplayAdded(displayId: Int) {}
        override fun onDisplayRemoved(displayId: Int) {}
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // MethodChannel — commands
        channel = MethodChannel(binding.binaryMessenger, "silkfps")
        channel.setMethodCallHandler(this)

        // EventChannel — real-time Hz stream to Dart
        eventChannel = EventChannel(binding.binaryMessenger, "silkfps/hz_stream")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                eventSink = sink
                android.util.Log.d(TAG, "Hz stream started ✓")
                // Send current Hz immediately on listen
                context?.let { ctx ->
                    val dm = ctx.getSystemService(Context.DISPLAY_SERVICE) as? DisplayManager
                    val hz = dm?.getDisplay(Display.DEFAULT_DISPLAY)?.mode?.refreshRate?.toDouble() ?: 60.0
                    sink?.success(hz)
                }
            }
            override fun onCancel(arguments: Any?) {
                eventSink = null
                android.util.Log.d(TAG, "Hz stream cancelled")
            }
        })

        context = binding.applicationContext
        displayManager = context?.getSystemService(Context.DISPLAY_SERVICE) as? DisplayManager
        android.util.Log.d(TAG, "Plugin attached ✓ | API: ${Build.VERSION.SDK_INT} | Strategy: ${getRendererStrategy()}")
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        if (Build.VERSION.SDK_INT >= MIN_SUPPORTED_API) {
            displayManager?.registerDisplayListener(displayListener, mainHandler)
            android.util.Log.d(TAG, "Activity attached + DisplayListener registered ✓")
        }
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        if (Build.VERSION.SDK_INT >= MIN_SUPPORTED_API) {
            displayManager?.registerDisplayListener(displayListener, mainHandler)
        }
    }

    override fun onDetachedFromActivity() {
        displayManager?.unregisterDisplayListener(displayListener)
        activity = null
        android.util.Log.d(TAG, "DisplayListener unregistered")
    }

    override fun onDetachedFromActivityForConfigChanges() {
        displayManager?.unregisterDisplayListener(displayListener)
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        android.util.Log.d(TAG, "Method: ${call.method}")

        if (Build.VERSION.SDK_INT < MIN_SUPPORTED_API) {
            when (call.method) {
                "getCurrentRefreshRate", "getSupportedRefreshRates",
                "isVulkanSupported", "getBatteryLevel", "getDeviceInfo" -> { /* continue */ }
                else -> {
                    result.error("API_NOT_SUPPORTED", "SilkFPS requires Android 11 (API 30) or higher", null)
                    return
                }
            }
        }

        when (call.method) {

            "setHighRefreshRate" -> {
                try {
                    val act = activity ?: return result.error("NO_ACTIVITY", "Activity not available", null)
                    targetRefreshRate = getMaxRefreshRate(act).toFloat()
                    android.util.Log.d(TAG, "setHighRefreshRate → target=${targetRefreshRate}Hz | strategy=${getRendererStrategy()}")
                    applyPreferredMode(act, targetRefreshRate)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }

            "setRefreshRate" -> {
                try {
                    val act = activity ?: return result.error("NO_ACTIVITY", "Activity not available", null)
                    val rate = call.argument<Double>("rate")?.toFloat()
                        ?: return result.error("INVALID_ARGS", "Rate is required", null)
                    targetRefreshRate = rate
                    android.util.Log.d(TAG, "setRefreshRate → target=${targetRefreshRate}Hz")
                    applyPreferredMode(act, targetRefreshRate)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }

            "getCurrentRefreshRate" -> {
                try {
                    val ctx = context ?: return result.error("NO_CONTEXT", "Context not available", null)
                    result.success(getActualRefreshRate(ctx))
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }

            "getSupportedRefreshRates" -> {
                try {
                    val act = activity ?: return result.error("NO_ACTIVITY", "Activity not available", null)
                    result.success(getSupportedRefreshRates(act))
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }

            "isVulkanSupported" -> {
                try {
                    val act = activity ?: return result.error("NO_ACTIVITY", "Activity not available", null)
                    result.success(isVulkanSupported(act))
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }

            "getBatteryLevel" -> {
                try {
                    val ctx = context ?: return result.error("NO_CONTEXT", "Context not available", null)
                    result.success(getBatteryLevel(ctx))
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }

            "getDeviceInfo" -> {
                try {
                    val act = activity ?: return result.error("NO_ACTIVITY", "Activity not available", null)
                    val ctx = context ?: return result.error("NO_CONTEXT", "Context not available", null)
                    val info = mapOf(
                        "manufacturer" to Build.MANUFACTURER,
                        "model" to Build.MODEL,
                        "androidVersion" to Build.VERSION.RELEASE,
                        "apiLevel" to Build.VERSION.SDK_INT,
                        "isVulkanSupported" to isVulkanSupported(act),
                        "isMetalSupported" to false,
                        "maxRefreshRate" to getMaxRefreshRate(act),
                        "currentRefreshRate" to getActualRefreshRate(ctx),
                        "supportedRefreshRates" to getSupportedRefreshRates(act),
                        "batteryLevel" to getBatteryLevel(ctx),
                        "rendererStrategy" to getRendererStrategy(),
                        "isHighRefreshRateSupported" to (Build.VERSION.SDK_INT >= MIN_SUPPORTED_API)
                    )
                    android.util.Log.d(TAG, "getDeviceInfo → $info")
                    result.success(info)
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }

            else -> result.notImplemented()
        }
    }

    // ─────────────────────────────────────────────────────────
    // RENDERER STRATEGY
    // ─────────────────────────────────────────────────────────
    private fun getRendererStrategy(): String {
        return when {
            Build.VERSION.SDK_INT < MIN_SUPPORTED_API -> "NOT_SUPPORTED"
            Build.VERSION.SDK_INT <= API_SKIA_MAX -> "SKIA"
            else -> "IMPELLER"
        }
    }

    // ─────────────────────────────────────────────────────────
    // CORE — preferredDisplayModeId
    // ─────────────────────────────────────────────────────────
    private fun applyPreferredMode(act: Activity, targetRate: Float) {
        if (Build.VERSION.SDK_INT < MIN_SUPPORTED_API) return
        try {
            val display = act.windowManager.defaultDisplay
            val currentMode = display.mode
            val supportedModes = display.supportedModes.filter {
                it.physicalWidth == currentMode.physicalWidth &&
                it.physicalHeight == currentMode.physicalHeight
            }

            val targetMode = if (targetRate >= getMaxRefreshRate(act).toFloat() - 1f) {
                supportedModes.maxByOrNull { it.refreshRate }
            } else {
                supportedModes.minByOrNull { Math.abs(it.refreshRate - targetRate) }
            }

            targetMode?.let { mode ->
                val params = act.window.attributes
                params.preferredDisplayModeId = mode.modeId
                act.window.attributes = params

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    act.window.frameRateBoostOnTouchEnabled = true
                }

                android.util.Log.d(TAG, "Applied → ${mode.refreshRate}Hz | modeId=${mode.modeId} ✓")
            }
        } catch (e: Exception) {
            android.util.Log.e(TAG, "applyPreferredMode error: ${e.message}")
        }
    }

    // ─────────────────────────────────────────────────────────
    // HELPERS
    // ─────────────────────────────────────────────────────────

    private fun getActualRefreshRate(ctx: Context): Double {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val dm = ctx.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
                dm.getDisplay(Display.DEFAULT_DISPLAY)?.mode?.refreshRate?.toDouble() ?: 60.0
            } else 60.0
        } catch (e: Exception) { 60.0 }
    }

    private fun getSupportedRefreshRates(act: Activity): List<Double> {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val display = act.windowManager.defaultDisplay
            val currentMode = display.mode
            display.supportedModes
                .filter {
                    it.physicalWidth == currentMode.physicalWidth &&
                    it.physicalHeight == currentMode.physicalHeight
                }
                .map { it.refreshRate.toDouble() }
                .sorted()
        } else {
            listOf(act.windowManager.defaultDisplay.refreshRate.toDouble())
        }
    }

    private fun getMaxRefreshRate(act: Activity): Double {
        return getSupportedRefreshRates(act).maxOrNull() ?: 60.0
    }

    private fun isVulkanSupported(act: Activity): Boolean {
        return try {
            act.packageManager.hasSystemFeature(PackageManager.FEATURE_VULKAN_HARDWARE_LEVEL) ||
            act.packageManager.hasSystemFeature("android.hardware.vulkan.level") ||
            act.packageManager.hasSystemFeature("android.hardware.vulkan.version")
        } catch (e: Exception) { false }
    }

    private fun getBatteryLevel(ctx: Context): Int {
        return try {
            val batteryStatus = ctx.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            val level = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
            val scale = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
            if (level == -1 || scale == -1) 100
            else (level * 100 / scale.toFloat()).toInt()
        } catch (e: Exception) { 100 }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        displayManager?.unregisterDisplayListener(displayListener)
        channel.setMethodCallHandler(null)
        eventSink = null
    }
}