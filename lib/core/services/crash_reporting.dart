import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Crashlytics stays off unless the release build passes
/// `--dart-define=ENABLE_CRASHLYTICS=true` and `android/app/google-services.json`
/// is present on the build machine. That json is gitignored.
const bool crashlyticsEnabled = bool.fromEnvironment('ENABLE_CRASHLYTICS');

class CrashReporting {
  static bool _crashlyticsReady = false;

  static Future<void> install() async {
    FlutterError.onError = (details) {
      developer.log(
        'FlutterError: ${details.exception}',
        name: 'FlutterError',
        error: details.exception,
        stackTrace: details.stack,
      );
      _record(details.exception, details.stack, fatal: true);
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      developer.log(
        'PlatformError: $error',
        name: 'PlatformError',
        error: error,
        stackTrace: stack,
      );
      _record(error, stack, fatal: true);
      return false;
    };

    if (!crashlyticsEnabled) {
      developer.log(
        'Crashlytics disabled. Pass --dart-define=ENABLE_CRASHLYTICS=true '
        'and add android/app/google-services.json to enable it.',
        name: 'CrashReporting',
      );
      return;
    }

    try {
      await Firebase.initializeApp();
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode,
      );
      _crashlyticsReady = true;
      developer.log('Crashlytics initialized', name: 'CrashReporting');
    } catch (error, stackTrace) {
      developer.log(
        'Crashlytics init failed. Add android/app/google-services.json '
        'from the Firebase console before enabling ENABLE_CRASHLYTICS. $error',
        name: 'CrashReporting',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static void logAdLoadFailure({
    required String format,
    int? code,
    String? domain,
    required String message,
  }) {
    final summary =
        'Ad load failure format=$format code=$code domain=$domain message=$message';
    developer.log(summary, name: 'AdService');
    if (!_crashlyticsReady) {
      return;
    }
    FirebaseCrashlytics.instance.log(summary);
  }

  static void _record(Object error, StackTrace? stack, {required bool fatal}) {
    if (!_crashlyticsReady) {
      return;
    }
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal);
  }
}
