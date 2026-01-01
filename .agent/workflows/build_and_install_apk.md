---
description: Build the Android APK and install it on a device
---

# Build and Install APK

This workflow will help you build the APK file for your Android device.

## Prerequisites
1. Ensure you have an Android device connected via USB.
2. Enable **Developer Options** and **USB Debugging** on your Android device.

## Option 1: Direct Install (Fastest for testing)
Run the following command to build and install directly to the connected phone:

// turbo
flutter run --release

## Option 2: Build APK File (For sharing)
If you want to generate an APK file to share or install manually later:

1. Build the APK:
// turbo
flutter build apk --release

2. Locate the APK:
   The built APK will be located at:
   `build/app/outputs/flutter-apk/app-release.apk`

3. Install manually:
   If you have `adb` installed (part of Android SDK), you can install the built APK:
// turbo
flutter install
