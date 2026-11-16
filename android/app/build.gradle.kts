import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Chave do release (#109): lida de android/key.properties, fora do git (modelo
// em key.properties.example). A mesma chave tem de assinar todas as versões:
// o Android só instala uma atualização por cima se a assinatura for igual.
val chaveDoRelease = Properties().apply {
    val arquivo = rootProject.file("key.properties")
    if (arquivo.exists()) FileInputStream(arquivo).use { load(it) }
}
val temChaveDoRelease = chaveDoRelease.getProperty("storeFile") != null

android {
    namespace = "com.example.sgc_msclean"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications (avisos, RF-015) usa APIs de data do
        // Java 8+ também nos Androids antigos
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Identificador do app instalado (#23). O namespace (pacote do código
        // Kotlin) continua com.example.sgc_msclean: não aparece para a usuária.
        // Trocar o applicationId depois de instalado exige desinstalar.
        applicationId = "br.com.msclean.agenda"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (temChaveDoRelease) {
                storeFile = file(chaveDoRelease.getProperty("storeFile"))
                storePassword = chaveDoRelease.getProperty("storePassword")
                keyAlias = chaveDoRelease.getProperty("keyAlias")
                keyPassword = chaveDoRelease.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

// Sem a chave, o release falha em vez de sair assinado com a de debug, que
// seria recusada na próxima atualização. Debug e testes seguem sem chave.
gradle.taskGraph.whenReady {
    val pedeRelease = allTasks.any { it.project == project && it.name.contains("Release") }
    if (pedeRelease && !temChaveDoRelease) {
        throw GradleException(
            "Falta android/key.properties com a chave do release " +
                "(modelo em android/key.properties.example; ver docs/arquitetura.md §12).",
        )
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
