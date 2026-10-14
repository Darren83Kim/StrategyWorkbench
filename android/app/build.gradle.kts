import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val admobAndroidTestAppId = "ca-app-pub-3940256099942544~3347511713"

fun readLocalEnvValue(key: String): String? {
    val envFile = rootProject.file("../.env")
    if (!envFile.exists()) {
        return null
    }

    return envFile.readLines()
        .asSequence()
        .map { it.trim() }
        .filter { it.isNotEmpty() && !it.startsWith("#") }
        .firstOrNull { it.startsWith("$key=") }
        ?.substringAfter("=")
        ?.trim()
        ?.takeIf {
            it.isNotEmpty() &&
                !it.contains("xxxxxxxx") &&
                !it.startsWith("your_")
        }
}

val admobAndroidAppId = readLocalEnvValue("ADMOB_ANDROID_APP_ID")
    ?: System.getenv("ADMOB_ANDROID_APP_ID")
    ?: admobAndroidTestAppId

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.round1studio.strategyworkbench"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.2.12479018"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.round1studio.strategyworkbench"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["admobApplicationId"] = admobAndroidAppId
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        debug {
            manifestPlaceholders["admobApplicationId"] = admobAndroidTestAppId
        }
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                // Build-test fallback only. Play upload must use android/key.properties.
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Required for Java 8+ API desugaring used by some plugins
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

fun decodeDartDefineToken(token: String): String {
    // Flutter passes --dart-define values as comma-separated base64. Padding
    // makes those tokens end with '=', so they must be decoded before splitting.
    if (token.matches(Regex("^[A-Za-z0-9+/]+={0,2}$"))) {
        try {
            val decoded = String(
                java.util.Base64.getDecoder().decode(token),
                Charsets.UTF_8,
            )
            if (decoded.contains('=')) {
                return decoded
            }
        } catch (_: IllegalArgumentException) {
        }
    }
    return token
}

fun decodedDartDefines(): Map<String, String> {
    val raw = (findProperty("dart-defines") as? String)?.trim().orEmpty()
    if (raw.isEmpty()) {
        return emptyMap()
    }
    val values = linkedMapOf<String, String>()
    for (token in raw.split(",")) {
        val trimmed = token.trim()
        if (trimmed.isEmpty()) {
            continue
        }
        val decoded = decodeDartDefineToken(trimmed)
        val separator = decoded.indexOf('=')
        if (separator <= 0) {
            continue
        }
        values[decoded.substring(0, separator)] = decoded.substring(separator + 1)
    }
    return values
}

fun isRejectedAdmobId(value: String?): Boolean {
    val trimmed = value?.trim().orEmpty()
    if (trimmed.isEmpty()) {
        return true
    }
    val lowered = trimmed.lowercase()
    return lowered.contains("xxxxxxxx") ||
        lowered.startsWith("your_") ||
        trimmed.contains(admobAndroidTestAppId.substringBefore("~"))
}

fun isForcingTestAds(value: String?): Boolean {
    return when (value?.trim()?.lowercase()) {
        "true", "1", "yes" -> true
        else -> false
    }
}

fun validateReleaseAdmobConfiguration() {
    val defines = decodedDartDefines()
    val failures = mutableListOf<String>()
    if (isForcingTestAds(defines["FORCE_ADMOB_TEST_IDS"])) {
        failures += "FORCE_ADMOB_TEST_IDS must not be set for a Play release."
    }
    if (isRejectedAdmobId(admobAndroidAppId)) {
        failures +=
            "AndroidManifest AdMob App ID placeholder is empty or a Google sample id."
    }
    for (key in listOf(
        "ADMOB_ANDROID_APP_ID",
        "ADMOB_ANDROID_BANNER_ID",
        "ADMOB_ANDROID_INTERSTITIAL_ID",
    )) {
        if (isRejectedAdmobId(defines[key])) {
            failures += "$key dart-define is empty or a Google sample id."
        }
    }
    if (failures.isNotEmpty()) {
        throw GradleException(
            "Release AdMob configuration rejected. " +
                "Play releases must be built with tool/build_play_release.ps1. " +
                failures.joinToString(" "),
        )
    }
}

// Debug/profile builds keep Google sample ads. Release tasks fail closed.
gradle.taskGraph.whenReady {
    val releaseBuild = allTasks.any { task ->
        val taskName = task.name
        taskName.contains("Release") && (
            taskName.startsWith("assemble") ||
                taskName.startsWith("bundle") ||
                taskName.contains("compileFlutterBuild")
            )
    }
    if (releaseBuild) {
        validateReleaseAdmobConfiguration()
    }
}

if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.crashlytics")
}
