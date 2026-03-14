package com.silkfps.silkfps_example
import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.content.pm.PackageManager

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setOptimalRefreshRate()
    }

    private fun isVulkanSupported(): Boolean {
        return try {
            packageManager.hasSystemFeature(PackageManager.FEATURE_VULKAN_HARDWARE_LEVEL) ||
            packageManager.hasSystemFeature("android.hardware.vulkan.level") ||
            packageManager.hasSystemFeature("android.hardware.vulkan.version")
        } catch (e: Exception) {
            false
        }
    }

    private fun setOptimalRefreshRate() {
        try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                val display = windowManager.defaultDisplay
                val currentMode = display.mode
                val optimalMode = display.supportedModes
                    .filter { it.physicalWidth == currentMode.physicalWidth && it.physicalHeight == currentMode.physicalHeight }
                    .maxByOrNull { it.refreshRate }

                optimalMode?.let {
                    val params = window.attributes
                    params.preferredDisplayModeId = it.modeId
                    window.attributes = params
                }
            }
            if (android.os.Build.VERSION.SDK_INT >= 34) {
                window.frameRateBoostOnTouchEnabled = true
            }
        } catch (e: Exception) {
            android.util.Log.e("RefreshRate", "Error: ${e.message}")
        }
    }
}
