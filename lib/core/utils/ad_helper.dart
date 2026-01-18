import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  static bool useTestAds = false; // ALWAYS use test ads during development

  // App ID for meta-data if needed (though usually handled in manifest/plist)
  static String get appId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-6268832217143150~9763008559';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-6268832217143150~2449071539'; // Example iOS App ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return useTestAds
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-6268832217143150/6759255470';
    } else if (Platform.isIOS) {
      return useTestAds
          ? 'ca-app-pub-3940256099942544/2934735716'
          : 'ca-app-pub-6268832217143150/8151859664';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return useTestAds
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-6268832217143150/7142398853';
    } else if (Platform.isIOS) {
      return useTestAds
          ? 'ca-app-pub-3940256099942544/1712485313'
          : 'ca-app-pub-6268832217143150/2573229783';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get appOpenAdUnitId {
    if (Platform.isAndroid) {
      return useTestAds
          ? 'ca-app-pub-3940256099942544/9257395921'
          : 'ca-app-pub-6268832217143150/5377595568';
    } else if (Platform.isIOS) {
      return useTestAds
          ? 'ca-app-pub-3940256099942544/5662855259'
          : 'ca-app-pub-6268832217143150/4155167660';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  /// Handles Consent (UMP) and then initializes Mobile Ads
  static Future<void> initialize() async {
    // SIMPLIFIED FOR DEBUGGING: Directly init ads, bypassing consent flow.
    // In production, you MUST restore the consent flow for GDPR/CPRA compliance.
    debugPrint('AdHelper: Initializing MobileAds directly (Debug Mode)');
    return _initializeMobileAds();
  }

  static Future<void> _initializeMobileAds() async {
    await MobileAds.instance.initialize();
    debugPrint('AdHelper: MobileAds initialized');
  }
}
