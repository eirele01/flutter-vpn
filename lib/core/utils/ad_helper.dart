import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  static bool useTestAds = false; // Set to false for production

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

  static String get mrecAdUnitId {
    if (Platform.isAndroid) {
      return useTestAds
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-6268832217143150/2895418072';
    } else if (Platform.isIOS) {
      return useTestAds
          ? 'ca-app-pub-3940256099942544/2934735716'
          : 'ca-app-pub-6268832217143150/0000000000';
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

  /// Handles Mobile Ads initialization
  static Future<void> initialize() async {
    // We simplified this to direct initialization.
    // Ensure you have "com.google.android.gms.ads.APPLICATION_ID" in AndroidManifest.xml
    await MobileAds.instance.initialize();
  }
}
