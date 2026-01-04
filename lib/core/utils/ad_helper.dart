import 'dart:io';

class AdHelper {
  static bool useTestAds = false; // Set to false for production

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return useTestAds
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-6268832217143150/6759255470';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
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
      return 'ca-app-pub-3940256099942544/1712485313';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
