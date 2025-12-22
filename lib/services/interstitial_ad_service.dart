import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InterstitialAdService {
  static InterstitialAd? _interstitialAd;
  static bool _isAdLoaded = false;
  
  // Ad Unit IDs
  static const String _androidAdUnitId = 'ca-app-pub-4969810842586372/7842325400';
  static const String _iosAdUnitId = 'ca-app-pub-4969810842586372/5026134966';
  
  // Test Ad Unit IDs (for development)
  static const String _androidTestAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _iosTestAdUnitId = 'ca-app-pub-3940256099942544/4411468910';
  
  // SharedPreferences keys
  static const String _keyLastAdShownTime = 'last_interstitial_ad_shown_time';
  static const String _keyFirstLoginAdShown = 'first_login_ad_shown';
  static const Duration _adInterval = Duration(hours: 4);

  /// Get ad unit ID based on platform
  /// Use test IDs in debug mode, real IDs in release mode
  static String get _adUnitId {
    if (Platform.isAndroid) {
      return kDebugMode ? _androidTestAdUnitId : _androidAdUnitId;
    } else if (Platform.isIOS) {
      return kDebugMode ? _iosTestAdUnitId : _iosAdUnitId;
    } else {
      return kDebugMode ? _androidTestAdUnitId : _androidAdUnitId; // Default to Android
    }
  }

  /// Load interstitial ad
  static Future<void> loadAd() async {
    if (_isAdLoaded && _interstitialAd != null) {
      return; // Ad already loaded
    }

    await InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          print('Interstitial ad loaded successfully');
          
          // Set full screen content callback
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              print('Interstitial ad dismissed');
              ad.dispose();
              _interstitialAd = null;
              _isAdLoaded = false;
              // Load next ad for future use
              loadAd();
            },
            onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
              print('Interstitial ad failed to show: $error');
              ad.dispose();
              _interstitialAd = null;
              _isAdLoaded = false;
              // Load next ad for future use
              loadAd();
            },
            onAdShowedFullScreenContent: (InterstitialAd ad) {
              print('Interstitial ad showed full screen content');
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Interstitial ad failed to load: $error');
          _interstitialAd = null;
          _isAdLoaded = false;
        },
      ),
    );
  }

  /// Check if ad should be shown
  /// Returns true if:
  /// - First login (first time showing ad after login) - only if isFirstLogin is true
  /// - Or 4 hours have passed since last ad
  static Future<bool> shouldShowAd({bool isFirstLogin = false}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // If first login, check if we've already shown ad for this login
    if (isFirstLogin) {
      final firstLoginAdShown = prefs.getBool(_keyFirstLoginAdShown) ?? false;
      if (!firstLoginAdShown) {
        return true; // Show ad on first login
      }
      return false; // Already shown for first login, don't show again
    }
    
    // For non-first-login checks, ignore first login flag
    // Check if 4 hours have passed since last ad
    final lastAdTimeMillis = prefs.getInt(_keyLastAdShownTime);
    if (lastAdTimeMillis == null) {
      return true; // Never shown before, show now
    }
    
    final lastAdTime = DateTime.fromMillisecondsSinceEpoch(lastAdTimeMillis);
    final now = DateTime.now();
    final timeSinceLastAd = now.difference(lastAdTime);
    
    return timeSinceLastAd >= _adInterval;
  }

  /// Show interstitial ad if conditions are met
  /// Returns true if ad was shown, false otherwise
  static Future<bool> showAdIfNeeded({bool isFirstLogin = false}) async {
    // Check if we should show ad
    final shouldShow = await shouldShowAd(isFirstLogin: isFirstLogin);
    if (!shouldShow) {
      return false;
    }

    // Load ad if not already loaded
    if (!_isAdLoaded || _interstitialAd == null) {
      await loadAd();
      // Wait a bit for ad to load
      await Future.delayed(const Duration(milliseconds: 1500));
    }

    // Show ad if loaded
    if (_isAdLoaded && _interstitialAd != null) {
      _interstitialAd!.show();
      
      // Save current time and first login flag
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastAdShownTime, DateTime.now().millisecondsSinceEpoch);
      if (isFirstLogin) {
        await prefs.setBool(_keyFirstLoginAdShown, true);
      }
      
      return true;
    }

    return false;
  }

  /// Mark first login ad as shown (call this after successful login)
  static Future<void> markFirstLoginAdShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstLoginAdShown, true);
  }

  /// Reset ad timing (for testing purposes or when user logs out)
  /// Only resets first login flag, keeps last ad time to respect 4-hour interval
  static Future<void> resetAdTiming() async {
    final prefs = await SharedPreferences.getInstance();
    // Only reset first login flag, keep last ad time
    // This ensures if user logs out and logs back in, they won't see ad immediately
    // unless 4 hours have passed
    await prefs.remove(_keyFirstLoginAdShown);
  }
  
  /// Reset all ad timing (for testing purposes only)
  static Future<void> resetAllAdTiming() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastAdShownTime);
    await prefs.remove(_keyFirstLoginAdShown);
  }

  /// Dispose ad
  static void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdLoaded = false;
  }
}

