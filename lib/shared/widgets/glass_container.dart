import 'dart:ui';

import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF), // white 10% opacity
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: const Color(0x33FFFFFF), // white 20% opacity
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
