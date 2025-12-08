import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Manages user consent for GDPR/CCPA compliance using Google UMP SDK
class ConsentManager {
  ConsentManager._();
  static final ConsentManager instance = ConsentManager._();

  bool _isInitialized = false;
  bool _canRequestAds = false;

  /// Initialize consent information and show consent form if required
  /// Returns true if ads can be requested
  Future<bool> initialize() async {
    if (_isInitialized) {
      return _canRequestAds;
    }

    // Only run on Android (iOS implementation would be similar)
    if (!Platform.isAndroid) {
      _isInitialized = true;
      _canRequestAds = true;
      return true;
    }

    try {
      // Configure UMP SDK parameters
      final params = ConsentRequestParameters();

      // Request consent information update
      final completer = Completer<bool>();

      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          // Success callback - consent information updated
          // Load and show consent form if required
          ConsentForm.loadAndShowConsentFormIfRequired((
            loadAndShowError,
          ) async {
            if (loadAndShowError != null) {
              // Consent gathering failed
              if (kDebugMode) {
                debugPrint('Consent form error: ${loadAndShowError.message}');
              }
            }

            // Check if we can request ads
            _canRequestAds = await ConsentInformation.instance.canRequestAds();
            _isInitialized = true;
            completer.complete(_canRequestAds);
          });
        },
        (FormError error) {
          // Error callback
          if (kDebugMode) {
            debugPrint('Consent info update error: ${error.message}');
          }
          _isInitialized = true;
          _canRequestAds = false;
          completer.complete(false);
        },
      );

      return await completer.future;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Consent initialization error: $e');
      }
      _isInitialized = true;
      _canRequestAds = false;
      return false;
    }
  }

  /// Check if ads can be requested
  /// Must call initialize() first
  bool canRequestAds() {
    if (!Platform.isAndroid) {
      return true;
    }

    return _canRequestAds;
  }

  /// Check if privacy options entry point is required
  Future<bool> isPrivacyOptionsRequired() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      return await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking privacy options: $e');
      }
      return false;
    }
  }

  /// Show privacy options form
  /// Call this from a privacy settings button in your app
  Future<void> showPrivacyOptionsForm() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      ConsentForm.showPrivacyOptionsForm((formError) {
        if (formError != null && kDebugMode) {
          debugPrint('Privacy options error: ${formError.message}');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error showing privacy options: $e');
      }
    }
  }

  /// Reset consent for testing purposes
  /// WARNING: Only use this for testing, not in production
  void resetConsentForTesting() {
    if (!Platform.isAndroid) return;

    try {
      ConsentInformation.instance.reset();
      _isInitialized = false;
      _canRequestAds = false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error resetting consent: $e');
      }
    }
  }

  /// Get current consent status for debugging
  Future<String> getConsentStatusString() async {
    if (!Platform.isAndroid) {
      return 'Not Required (Non-Android)';
    }

    try {
      final status = await ConsentInformation.instance.getConsentStatus();
      switch (status) {
        case ConsentStatus.obtained:
          return 'Obtained';
        case ConsentStatus.required:
          return 'Required';
        case ConsentStatus.notRequired:
          return 'Not Required';
        case ConsentStatus.unknown:
          return 'Unknown';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }
}
