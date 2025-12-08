import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../services/ad_service.dart';
import '../../services/screen_ad_manager.dart';

/// Banner Ad Widget - Reuses ads across navigation (AdMob compliant)
///
/// Uses ScreenAdManager to maintain one ad per screen. The same ad instance
/// is reused across navigation, preventing excessive impressions.
///
/// Usage:
/// ```dart
/// BannerAdWidget(screenId: 'home_screen')
/// ```
class BannerAdWidget extends StatelessWidget {
  final String screenId;

  const BannerAdWidget({super.key, required this.screenId});

  @override
  Widget build(BuildContext context) {
    if (!AdService.isAdsSupported) {
      return const SizedBox.shrink();
    }

    // Get or create ad from manager
    final ad = ScreenAdManager.instance.getOrCreateBannerAd(screenId);
    final isLoaded = ScreenAdManager.instance.isBannerLoaded(screenId);

    if (ad == null) {
      return const SizedBox.shrink();
    }

    // Show loading placeholder if ad is not yet loaded
    if (!isLoaded) {
      return Container(
        alignment: Alignment.center,
        width: 320,
        height: 50,
        child:
            const SizedBox.shrink(), // Invisible placeholder to reserve space
      );
    }

    return Container(
      alignment: Alignment.center,
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
