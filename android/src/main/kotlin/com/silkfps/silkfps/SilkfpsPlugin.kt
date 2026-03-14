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
import android.view.Display
import android.view.Surface

class SilkfpsPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var context: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "silkfps")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {

            "setHighRefreshRate" -> {
                try {
                    val act = activity ?: return result.error("NO_ACTIVITY", "Activity not available", null)
                    setOptimalRefreshRate(act)
                    act.window.decorView.postDelayed({ setOptimalRefreshRate(act) }, 300)
                    act.window.decorView.postDelayed({ setOptimalRefreshRate(act) }, 800)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }

            "setRefreshRate" -> {
                try {
                    val act = activity ?: return result.error("NO_ACTIVITY", "Activity not available", null)
                    val targetRate = call.argument<Double>("rate")?.toFloat()
                        ?: return result.error("INVALID_ARGS", "Rate is required", null)
                    setCustomRefreshRate(act, targetRate)
                    act.window.decorView.postDelayed({ setCustomRefreshRate(act, targetRate) }, 300)
                    act.window.decorView.postDelayed({ setCustomRefreshRate(act, targetRate) }, 800)
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
                    result.success(info)
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }

            else -> result.notImplemented()
        }
    }

    // ─────────────────────────────────────────────────────────
    // PRIVATE FUNCTIONS
    // ─────────────────────────────────────────────────────────

    private fun setOptimalRefreshRate(act: Activity) {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            val display = act.windowManager.defaultDisplay
            val currentMode = display.mode
            val optimalMode = display.supportedModes
                .filter {
                    it.physicalWidth == currentMode.physicalWidth &&
                    it.physicalHeight == currentMode.physicalHeight
                }
                .maxByOrNull { it.refreshRate }

            optimalMode?.let {
                // Level 1 — preferredDisplayModeId (API 23+) — all devices
                val params = act.window.attributes
                params.preferredDisplayModeId = it.modeId
                act.window.attributes = params

                // Level 2 — Surface.setFrameRate() (API 30+)
                // This bypasses Flutter engine renderer — works on OpenGLES devices too
                // Same approach used by Binance, MEXC, and other production apps
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                    try {
                        act.window.peekDecorView()?.rootSurface?.setFrameRate(
                            it.refreshRate,
                            Surface.FRAME_RATE_COMPATIBILITY_FIXED_SOURCE,
                            Surface.CHANGE_FRAME_RATE_ALWAYS
                        )
                    } catch (_: Exception) {}

                    // Also apply on decorView surface directly
                    act.window.decorView.postDelayed({
                        try {
                            act.window.peekDecorView()?.rootSurface?.setFrameRate(
                                it.refreshRate,
                                Surface.FRAME_RATE_COMPATIBILITY_FIXED_SOURCE,
                                Surface.CHANGE_FRAME_RATE_ALWAYS
                            )
                        } catch (_: Exception) {}
                    }, 500)
                }

                // Level 3 — Android 14+ touch boost
                if (android.os.Build.VERSION.SDK_INT >= 34) {
                    act.window.frameRateBoostOnTouchEnabled = true
                }

                android.util.Log.d(
                    "SilkFPS",
                    "Target: ${it.refreshRate}Hz | " +
                    "API: ${android.os.Build.VERSION.SDK_INT} | " +
                    "SurfaceAPI: ${android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R}"
                )
            }
        }
    }

    private fun setCustomRefreshRate(act: Activity, targetRate: Float) {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            val display = act.windowManager.defaultDisplay
            val currentMode = display.mode
            val targetMode = display.supportedModes
                .filter {
                    it.physicalWidth == currentMode.physicalWidth &&
                    it.physicalHeight == currentMode.physicalHeight
                }
                .minByOrNull { Math.abs(it.refreshRate - targetRate) }

            targetMode?.let {
                // Level 1 — preferredDisplayModeId
                val params = act.window.attributes
                params.preferredDisplayModeId = it.modeId
                act.window.attributes = params

                // Level 2 — Surface.setFrameRate() (API 30+)
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                    try {
                        act.window.peekDecorView()?.rootSurface?.setFrameRate(
                            targetRate,
                            Surface.FRAME_RATE_COMPATIBILITY_FIXED_SOURCE,
                            Surface.CHANGE_FRAME_RATE_ALWAYS
                        )
                    } catch (_: Exception) {}
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────
    // Get ACTUAL refresh rate from DisplayManager
    // Not from window mode — that value can be stale/outdated
    // ─────────────────────────────────────────────────────────
    private fun getActualRefreshRate(ctx: Context): Double {
        return try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                val displayManager = ctx.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
                val display = displayManager.getDisplay(Display.DEFAULT_DISPLAY)
                display?.mode?.refreshRate?.toDouble() ?: 60.0
            } else {
                60.0
            }
        } catch (e: Exception) {
            60.0
        }
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
        } catch (e: Exception) {
            false
        }
    }

    private fun getBatteryLevel(ctx: Context): Int {
        return try {
            val intentFilter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
            val batteryStatus = ctx.registerReceiver(null, intentFilter)
            val level = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
            val scale = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
            if (level == -1 || scale == -1) 100
            else (level * 100 / scale.toFloat()).toInt()
        } catch (e: Exception) {
            100
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}