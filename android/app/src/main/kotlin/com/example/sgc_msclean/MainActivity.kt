package com.example.sgc_msclean

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.ContactsContract
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Seletor de contatos em andamento (RF-016, issue #115).
    private var contatoPendente: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Liberação da economia de bateria para os avisos (RF-015, issue #101).
        // Par do lib/services/bateria.dart.
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
        // Contato do celular (RF-016, issue #115). Par do
        // lib/services/contatos.dart. O seletor do sistema devolve só o número
        // tocado, com permissão temporária de leitura: o app não pede
        // READ_CONTACTS nem vê a agenda inteira.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "msclean/contatos")
            .setMethodCallHandler { chamada, resultado ->
                if (chamada.method != "escolher") {
                    resultado.notImplemented()
                    return@setMethodCallHandler
                }
                contatoPendente?.success(null) // pedido anterior abandonado
                contatoPendente = resultado
                try {
                    @Suppress("DEPRECATION")
                    startActivityForResult(
                        Intent(Intent.ACTION_PICK, ContactsContract.CommonDataKinds.Phone.CONTENT_URI),
                        PEDIDO_CONTATO,
                    )
                } catch (_: Exception) {
                    contatoPendente = null
                    resultado.success(null)
                }
            }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PEDIDO_CONTATO) return
        val resultado = contatoPendente ?: return
        contatoPendente = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            resultado.success(null)
            return
        }
        resultado.success(lerContato(uri))
    }

    private fun lerContato(uri: Uri): Map<String, String>? = try {
        contentResolver.query(
            uri,
            arrayOf(
                ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                ContactsContract.CommonDataKinds.Phone.NUMBER,
            ),
            null, null, null,
        )?.use { cursor ->
            if (!cursor.moveToFirst()) return@use null
            mapOf(
                "nome" to (cursor.getString(0) ?: ""),
                "telefone" to (cursor.getString(1) ?: ""),
            )
        }
    } catch (_: Exception) {
        null
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

    private companion object {
        const val PEDIDO_CONTATO = 4115
    }
}
