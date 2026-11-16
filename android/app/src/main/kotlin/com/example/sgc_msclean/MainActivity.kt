package com.example.sgc_msclean

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Liberação da economia de bateria para os avisos (RF-015, issue #101).
    // Par do lib/services/bateria.dart.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "msclean/bateria")
            .setMethodCallHandler { chamada, resultado ->
                when (chamada.method) {
                    "liberada" -> resultado.success(liberada())
                    "pedir" -> {
                        pedir()
                        resultado.success(null)
                    }
                    else -> resultado.notImplemented()
                }
            }
    }

    // Antes do Android 6 não existe economia de bateria por app.
    private fun liberada(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val energia = getSystemService(POWER_SERVICE) as PowerManager
        return energia.isIgnoringBatteryOptimizations(packageName)
    }

    // Diálogo do sistema: "Permitir que o app seja executado em segundo plano?"
    private fun pedir() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        try {
            startActivity(
                Intent(
                    Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                    Uri.parse("package:$packageName"),
                ),
            )
        } catch (_: Exception) {
            // aparelho sem o diálogo: fica o passo manual
        }
    }
}
