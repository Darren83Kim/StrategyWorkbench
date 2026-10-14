const googleSampleAdmobPublisher = 'ca-app-pub-3940256099942544';

bool isRejectedProductionAdmobId(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return true;
  }
  final lowered = trimmed.toLowerCase();
  if (lowered.contains('xxxxxxxx') || lowered.startsWith('your_')) {
    return true;
  }
  return trimmed.contains(googleSampleAdmobPublisher);
}

bool isForcingAdmobTestIds(String rawValue) {
  switch (rawValue.trim().toLowerCase()) {
    case 'true':
    case '1':
    case 'yes':
      return true;
    default:
      return false;
  }
}

/// Release binaries must not ship empty or Google sample AdMob IDs.
/// Gradle enforces the same rule before an Android release artifact is built.
void ensureReleaseAdmobIds({
  required bool isReleaseBuild,
  required String appId,
  required String bannerId,
  required String interstitialId,
  required bool forceTestIds,
}) {
  if (!isReleaseBuild) {
    return;
  }

  if (forceTestIds) {
    throw StateError(
      'Release AdMob configuration rejected: FORCE_ADMOB_TEST_IDS is set. '
      'Build Play releases only with tool/build_play_release.ps1.',
    );
  }

  final rejected = <String>[
    if (isRejectedProductionAdmobId(appId)) 'ADMOB_ANDROID_APP_ID',
    if (isRejectedProductionAdmobId(bannerId)) 'ADMOB_ANDROID_BANNER_ID',
    if (isRejectedProductionAdmobId(interstitialId))
      'ADMOB_ANDROID_INTERSTITIAL_ID',
  ];
  if (rejected.isEmpty) {
    return;
  }

  throw StateError(
    'Release AdMob configuration rejected: ${rejected.join(', ')} '
    'is empty or a Google sample id. '
    'Build Play releases only with tool/build_play_release.ps1.',
  );
}
