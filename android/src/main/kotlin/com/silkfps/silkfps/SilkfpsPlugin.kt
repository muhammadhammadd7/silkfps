package com.silkfps.silkfps

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
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
import android.os.Handler
import android.os.Looper
import android.view.Display

class SilkfpsPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var context: Context? = null

    private var targetRefreshRate: Float = 0f
    private var displayManager: DisplayManager? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    companion object {
        private const val TAG = "SilkFPS"
    }

    // ─────────────────────────────────────────────────────────
    // DisplayListener — fires instantly when OS changes rate
    // No polling, no battery waste — event-driven
    // ─────────────────────────────────────────────────────────
    private val displayListener = object : DisplayManager.DisplayListener {
        override fun onDisplayChanged(displayId: Int) {
            if (displayId != Display.DEFAULT_DISPLAY) return
            if (targetRefreshRate <= 0f) return
            val act = activity ?: return

            val currentRate = act.windowManager.defaultDisplay.mode.refreshRate
            if (currentRate < targetRefreshRate - 1f) {
                android.util.Log.w(TAG, "DisplayListener: OS changed to ${currentRate}Hz → re-applying ${targetRefreshRate}Hz")
                mainHandler.post { applyPreferredMode(act, targetRefreshRate) }
            }
        }
        override fun onDisplayAdded(displayId: Int) {}
        override fun onDisplayRemoved(displayId: Int) {}
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "silkfps")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
        displayManager = context?.getSystemService(Context.DISPLAY_SERVICE) as? DisplayManager
        android.util.Log.d(TAG, "Plugin attached ✓")
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        // Register DisplayListener — starts watching for OS rate changes
        displayManager?.registerDisplayListener(displayListener, mainHandler)
        android.util.Log.d(TAG, "Activity attached + DisplayListener registered ✓")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        displayManager?.registerDisplayListener(displayListener, mainHandler)
    }

    override fun onDetachedFromActivity() {
        displayManager?.unregisterDisplayListener(displayListener)
        activity = null
        android.util.Log.d(TAG, "Activity detached + DisplayListener unregistered")
    }

    override fun onDetachedFromActivityForConfigChanges() {
        displayManager?.unregisterDisplayListener(displayListener)
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        android.util.Log.d(TAG, "Method: ${call.method}")
        when (call.method) {

            "setHighRefreshRate" -> {
                try {
                    val act = activity ?: return result.error("NO_ACTIVITY", "Activity not available", null)
                    targetRefreshRate = getMaxRefreshRate(act).toFloat()
                    android.util.Log.d(TAG, "setHighRefreshRate → target=${targetRefreshRate}Hz")
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
                        "manufacturer" to android.os.Build.MANUFACTURER,
                        "model" to android.os.Build.MODEL,
                        "androidVersion" to android.os.Build.VERSION.RELEASE,
                        "apiLevel" to android.os.Build.VERSION.SDK_INT,
                        "isVulkanSupported" to isVulkanSupported(act),
                        "isMetalSupported" to false,
                        "maxRefreshRate" to getMaxRefreshRate(act),
                        "currentRefreshRate" to getActualRefreshRate(ctx),
                        "supportedRefreshRates" to getSupportedRefreshRates(act),
                        "batteryLevel" to getBatteryLevel(ctx)
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
    // CORE — Set preferredDisplayModeId
    // This is all flutter_displaymode does too — clean & proven
    // Works on 60Hz, 90Hz, 120Hz, 144Hz devices automatically
    // ─────────────────────────────────────────────────────────
    private fun applyPreferredMode(act: Activity, targetRate: Float) {
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.M) return
        try {
            val display = act.windowManager.defaultDisplay
            val currentMode = display.mode
            val supportedModes = display.supportedModes.filter {
                it.physicalWidth == currentMode.physicalWidth &&
                it.physicalHeight == currentMode.physicalHeight
            }

            // Find the mode closest to target rate
            val targetMode = if (targetRate >= getMaxRefreshRate(act).toFloat() - 1f) {
                supportedModes.maxByOrNull { it.refreshRate }
            } else {
                supportedModes.minByOrNull { Math.abs(it.refreshRate - targetRate) }
            }

            targetMode?.let { mode ->
                val params = act.window.attributes
                params.preferredDisplayModeId = mode.modeId
                act.window.attributes = params

                // Android 14+ touch boost
                if (android.os.Build.VERSION.SDK_INT >= 34) {
                    act.window.frameRateBoostOnTouchEnabled = true
                }

                android.util.Log.d(TAG, "Applied → modeId=${mode.modeId} | ${mode.refreshRate}Hz ✓")
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
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                val dm = ctx.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
                dm.getDisplay(Display.DEFAULT_DISPLAY)?.mode?.refreshRate?.toDouble() ?: 60.0
            } else 60.0
        } catch (e: Exception) { 60.0 }
    }

    private fun getSupportedRefreshRates(act: Activity): List<Double> {
        return if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
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
    }
}