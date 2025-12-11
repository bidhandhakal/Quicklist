import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_service.dart';

/// Manages App Open Ads and shows them when the app comes to foreground
class AppOpenAdManager {
  static final AppOpenAdManager _instance = AppOpenAdManager._internal();
  factory AppOpenAdManager() => _instance;
  AppOpenAdManager._internal();

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  bool _isLoadingAd = false;
  DateTime? _appOpenLoadTime;
  int _loadAttempts = 0;
  static const int _maxLoadAttempts = 3;

  /// Maximum duration allowed between ad load and show
  final Duration maxCacheDuration = const Duration(hours: 4);

  /// Load an app open ad
  Future<void> loadAd() async {
    // Only load ads on Android
    if (!AdService.isAdsSupported) {
      debugPrint('AppOpenAd: Ads not supported on this platform');
      return;
    }

    // Don't load if already loading or showing
    if (_appOpenAd != null || _isShowingAd || _isLoadingAd) {
      debugPrint('AppOpenAd: Ad already loaded, loading, or showing');
      return;
    }

    _isLoadingAd = true;
    debugPrint('AppOpenAd: Loading ad (attempt ${_loadAttempts + 1})...');

    try {
      await AppOpenAd.load(
        adUnitId: AdService.appOpenAdUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('AppOpenAd: Ad loaded successfully');
            _appOpenAd = ad;
            _appOpenLoadTime = DateTime.now();
            _isLoadingAd = false;
            _loadAttempts = 0;
          },
          onAdFailedToLoad: (error) {
            debugPrint('AppOpenAd: Failed to load ad: ${error.message}');
            _appOpenAd = null;
            _isLoadingAd = false;
            _loadAttempts++;

            // Retry loading if under max attempts
            if (_loadAttempts < _maxLoadAttempts) {
              debugPrint('AppOpenAd: Retrying in 5 seconds...');
              Future.delayed(const Duration(seconds: 5), loadAd);
            } else {
              debugPrint('AppOpenAd: Max load attempts reached');
              _loadAttempts = 0;
            }
          },
        ),
      );
    } catch (e) {
      debugPrint('AppOpenAd: Exception loading ad: $e');
      _isLoadingAd = false;
      _appOpenAd = null;
    }
  }

  /// Check if an ad is available and not expired
  bool get isAdAvailable {
    if (_appOpenAd == null) return false;
    if (_appOpenLoadTime == null) return false;

    final timeSinceLoad = DateTime.now().difference(_appOpenLoadTime!);
    return timeSinceLoad < maxCacheDuration;
  }

  /// Show the app open ad
  void showAdIfAvailable() {
    // Only show ads on Android
    if (!AdService.isAdsSupported) {
      debugPrint('AppOpenAd: Ads not supported on this platform');
      return;
    }

    if (!isAdAvailable) {
      debugPrint('AppOpenAd: No ad available to show');
      loadAd();
      return;
    }

    if (_isShowingAd) {
      debugPrint('AppOpenAd: Already showing an ad');
      return;
    }

    debugPrint('AppOpenAd: Showing ad');
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        debugPrint('AppOpenAd: Ad showed full screen content');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint(
          'AppOpenAd: Failed to show full screen content: ${error.message}',
        );
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('AppOpenAd: Ad dismissed full screen content');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
    );

    _appOpenAd!.show();
  }

  /// Dispose the current ad
  void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
  }
}
