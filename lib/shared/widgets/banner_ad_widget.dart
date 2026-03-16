// TODO(ads): google_mobile_ads 연동 시 아래 구현 복원
// pubspec.yaml에 google_mobile_ads: any 추가 및
// AndroidManifest.xml에 AdMob App ID 등록 후 사용

import 'package:flutter/material.dart';

/// 광고 미연동 상태: 빈 위젯 반환 (공간 차지 없음)
class BannerAdWidget extends StatelessWidget {
  const BannerAdWidget({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
