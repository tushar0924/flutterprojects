package com.example.flutterprojects

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val channelName = "google_maps_api_key"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"getAndroidMapsApiKey" -> result.success(resolveGoogleMapsApiKey())
					else -> result.notImplemented()
				}
			}
	}

	private fun resolveGoogleMapsApiKey(): String? {
		return try {
			val applicationInfo = packageManager.getApplicationInfo(
				packageName,
				PackageManager.GET_META_DATA,
			)
			applicationInfo.metaData?.getString("com.google.android.geo.API_KEY")
		} catch (_: Exception) {
			null
		}
	}
}
