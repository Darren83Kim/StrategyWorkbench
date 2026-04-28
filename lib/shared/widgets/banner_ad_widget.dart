import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    if (!AdService().isAvailable) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadBannerAfterStartup());
    });
  }

  Future<void> _loadBannerAfterStartup() async {
    const delay =
        kDebugMode ? Duration(seconds: 4) : Duration(milliseconds: 900);
    await Future<void>.delayed(delay);

    if (!mounted) {
      return;
    }

    await _loadBanner();
  }

  Future<void> _loadBanner() async {
    final adService = AdService();
    await adService.init();

    if (!mounted || !adService.isInitialized) {
      return;
    }

    final adUnitId = adService.bannerAdUnitId;
    if (adUnitId == null || adUnitId.isEmpty) {
      return;
    }

    final banner = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          developer.log(
            'Banner ad failed to load: $error',
            name: 'BannerAdWidget',
          );
          ad.dispose();
          if (!mounted) {
            return;
          }
          setState(() {
            _bannerAd = null;
            _isLoaded = false;
          });
        },
      ),
    );

    try {
      banner.load();
    } catch (error, stackTrace) {
      developer.log(
        'Banner ad load threw: $error',
        name: 'BannerAdWidget',
        error: error,
        stackTrace: stackTrace,
      );
      banner.dispose();
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Material(
      color: const Color(0xFF0B1220),
      child: SafeArea(
        top: false,
        bottom: false,
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }
}
