import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_service.dart';

/// Manages cached ad instances to prevent reloading on navigation
///
/// Ads are cached per screen ID and reused when navigating back.
/// This prevents unnecessary ad reloads and improves performance.
class AdCacheManager {
  AdCacheManager._();
  static final AdCacheManager instance = AdCacheManager._();

  final Map<String, BannerAd> _bannerCache = {};
  final Map<String, NativeAd> _nativeCache = {};
  final Map<String, DateTime> _bannerLoadTimes = {};
  final Map<String, DateTime> _nativeLoadTimes = {};
  final Map<String, bool> _bannerLoadingState = {};
  final Map<String, bool> _nativeLoadingState = {};

  // Refresh ads after 60 seconds
  static const Duration _refreshInterval = Duration(seconds: 60);

  /// Get or create a banner ad for the given screen
  /// Returns cached ad if available, otherwise creates and loads a new one
  Future<BannerAd?> getBannerAd(
    String screenId, {
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
  }) async {
    if (!AdService.isAdsSupported) return null;

    // Check if we have a cached ad that's still fresh and loaded
    if (_bannerCache.containsKey(screenId)) {
      final loadTime = _bannerLoadTimes[screenId];
      final isLoaded = _bannerLoadingState[screenId] ?? false;

      if (loadTime != null &&
          isLoaded &&
          DateTime.now().difference(loadTime) < _refreshInterval) {
        // Return existing cached ad
        return _bannerCache[screenId];
      } else {
        // Ad is stale or failed, dispose and create new one
        _bannerCache[screenId]?.dispose();
        _bannerCache.remove(screenId);
        _bannerLoadTimes.remove(screenId);
        _bannerLoadingState.remove(screenId);
      }
    }

    // Mark as loading
    _bannerLoadingState[screenId] = false;

    // Create new banner ad
    final bannerAd = AdService().createBannerAd(
      onAdLoaded: (ad) {
        _bannerLoadTimes[screenId] = DateTime.now();
        _bannerLoadingState[screenId] = true;
        onAdLoaded(ad);
      },
      onAdFailedToLoad: (ad, error) {
        _bannerCache.remove(screenId);
        _bannerLoadTimes.remove(screenId);
        _bannerLoadingState.remove(screenId);
        onAdFailedToLoad(ad, error);
      },
    );

    if (bannerAd != null) {
      _bannerCache[screenId] = bannerAd;
      // Load the ad immediately
      await bannerAd.load();
    }

    return bannerAd;
  }

  /// Get or create a native ad for the given screen
  /// Returns cached ad if available, otherwise creates and loads a new one
  Future<NativeAd?> getNativeAd(
    String screenId, {
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
  }) async {
    if (!AdService.isAdsSupported) return null;

    // Check if we have a cached ad that's still fresh and loaded
    if (_nativeCache.containsKey(screenId)) {
      final loadTime = _nativeLoadTimes[screenId];
      final isLoaded = _nativeLoadingState[screenId] ?? false;

      if (loadTime != null &&
          isLoaded &&
          DateTime.now().difference(loadTime) < _refreshInterval) {
        // Return existing cached ad
        return _nativeCache[screenId];
      } else {
        // Ad is stale or failed, dispose and create new one
        _nativeCache[screenId]?.dispose();
        _nativeCache.remove(screenId);
        _nativeLoadTimes.remove(screenId);
        _nativeLoadingState.remove(screenId);
      }
    }

    // Mark as loading
    _nativeLoadingState[screenId] = false;

    // Create new native ad
    final nativeAd = NativeAd(
      adUnitId: AdService.nativeAdUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _nativeLoadTimes[screenId] = DateTime.now();
          _nativeLoadingState[screenId] = true;
          onAdLoaded(ad);
        },
        onAdFailedToLoad: (ad, error) {
          _nativeCache.remove(screenId);
          _nativeLoadTimes.remove(screenId);
          _nativeLoadingState.remove(screenId);
          onAdFailedToLoad(ad, error);
        },
      ),
      nativeAdOptions: NativeAdOptions(
        adChoicesPlacement: AdChoicesPlacement.topRightCorner,
      ),
      factoryId: 'adFactory',
    );

    _nativeCache[screenId] = nativeAd;
    // Load the ad immediately
    await nativeAd.load();

    return nativeAd;
  }

  /// Check if a banner ad is cached and fresh
  bool hasFreshBannerAd(String screenId) {
    if (!_bannerCache.containsKey(screenId)) return false;

    final loadTime = _bannerLoadTimes[screenId];
    final isLoaded = _bannerLoadingState[screenId] ?? false;
    if (loadTime == null || !isLoaded) return false;

    return DateTime.now().difference(loadTime) < _refreshInterval;
  }

  /// Check if a native ad is cached and fresh
  bool hasFreshNativeAd(String screenId) {
    if (!_nativeCache.containsKey(screenId)) return false;

    final loadTime = _nativeLoadTimes[screenId];
    final isLoaded = _nativeLoadingState[screenId] ?? false;
    if (loadTime == null || !isLoaded) return false;

    return DateTime.now().difference(loadTime) < _refreshInterval;
  }

  /// Clear a specific banner ad from cache
  void clearBannerAd(String screenId) {
    _bannerCache[screenId]?.dispose();
    _bannerCache.remove(screenId);
    _bannerLoadTimes.remove(screenId);
    _bannerLoadingState.remove(screenId);
  }

  /// Clear a specific native ad from cache
  void clearNativeAd(String screenId) {
    _nativeCache[screenId]?.dispose();
    _nativeCache.remove(screenId);
    _nativeLoadTimes.remove(screenId);
    _nativeLoadingState.remove(screenId);
  }

  /// Clear all cached ads (call on app termination)
  void clearAll() {
    for (var ad in _bannerCache.values) {
      ad.dispose();
    }
    for (var ad in _nativeCache.values) {
      ad.dispose();
    }
    _bannerCache.clear();
    _nativeCache.clear();
    _bannerLoadTimes.clear();
    _nativeLoadTimes.clear();
    _bannerLoadingState.clear();
    _nativeLoadingState.clear();
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'banner_count': _bannerCache.length,
      'native_count': _nativeCache.length,
      'banner_screens': _bannerCache.keys.toList(),
      'native_screens': _nativeCache.keys.toList(),
    };
  }
}
