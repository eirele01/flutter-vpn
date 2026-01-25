# Production Release Guide

You are now ready to build the production version of **BaganiVPN**.

## 1. Signing Configuration (Required)

You must sign your app to release it on the Play Store.

1.  **Generate a Keystore** (If you haven't already):
    Run this in your terminal:

    ```powershell
    keytool -genkey -v -keystore c:\Users\EJ\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
    ```

    _Keep this file SAFE. If you lose it, you can't update your app._

2.  **Create `key.properties`**:
    Create a file named `key.properties` in `android/` with the following content:

    ```properties
    storePassword=YOUR_STORE_PASSWORD
    keyPassword=YOUR_KEY_PASSWORD
    keyAlias=upload
    storeFile=c:/Users/EJ/upload-keystore.jks
    ```

3.  **Update `android/app/build.gradle`**:
    Ensure your `build.gradle` is configured to read from `key.properties`. (Usually, standard Flutter projects have this set up, but verify if `signingConfigs` is present in `android {}` block).

## 2. Updated AdMob Settings

I have automatically updated `lib/core/utils/ad_helper.dart` for you:

- `useTestAds` is now **`false`**.
- **UMP/GDPR Consent** flow is enabled.

## 3. Verify Version

Check `pubspec.yaml` and ensure the version is correct:

```yaml
version: 1.0.0+1
```

Increment the `+1` (build number) for every new release you upload.

## 4. Build Command

To build the **App Bundle (.aab)** for Play Store upload, run:

```powershell
flutter build appbundle --release
```

The output file will be in `build/app/outputs/bundle/release/app-release.aab`.
This file is what you upload to the Google Play Console! 🚀
