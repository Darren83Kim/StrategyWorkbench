import 'package:flutter/foundation.dart';
import 'dart:ui';

import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final bool enableBlur;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.blurSigma = 10.0,
    this.enableBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: const Color(0x1AFFFFFF), // white 10% opacity
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: const Color(0x33FFFFFF), // white 20% opacity
        width: 1.0,
      ),
    );

    // Debug/emulator 환경에서는 BackdropFilter가 매우 비싸서 입력 반응성이 크게 떨어진다.
    // 이 경우에는 동일한 톤의 반투명 패널만 사용해 개발 중 체감을 우선한다.
    if (kDebugMode || !enableBlur) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: RepaintBoundary(
          child: DecoratedBox(
            decoration: decoration,
            child: child,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: RepaintBoundary(
          child: DecoratedBox(
            decoration: decoration,
            child: child,
          ),
        ),
      ),
    );
  }
}
