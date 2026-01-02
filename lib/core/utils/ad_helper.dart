import 'dart:io';

class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      // return 'ca-app-pub-3940256099942544/6300978111'; // Android Test ID
      return 'ca-app-pub-6268832217143150/6759255470'; // Real ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // iOS Test ID
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      // return 'ca-app-pub-3940256099942544/5224354917'; // Android Test ID
      return 'ca-app-pub-6268832217143150/7142398853'; // Real ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // iOS Test ID
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
