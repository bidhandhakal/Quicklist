import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../services/ad_service.dart';
import '../../services/screen_ad_manager.dart';

/// Native Ad Widget - Reuses ads across navigation (AdMob compliant)
///
/// Uses ScreenAdManager to maintain one ad per screen. The same ad instance
/// is reused across navigation, preventing excessive impressions.
///
/// Usage:
/// ```dart
/// NativeAdWidget(screenId: 'home_feed')
/// ```
class NativeAdWidget extends StatelessWidget {
  final String screenId;

  const NativeAdWidget({super.key, required this.screenId});

  @override
  Widget build(BuildContext context) {
    if (!AdService.isAdsSupported) {
      return const SizedBox.shrink();
    }

    // Get or create ad from manager
    final ad = ScreenAdManager.instance.getOrCreateNativeAd(screenId);
    final isLoaded = ScreenAdManager.instance.isNativeLoaded(screenId);

    if (ad == null) {
      return const SizedBox.shrink();
    }

    // Show loading placeholder if ad is not yet loaded
    if (!isLoaded) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        height: 200,
        child:
            const SizedBox.shrink(), // Invisible placeholder to reserve space
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        color: Colors.white,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 200, maxHeight: 350),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
