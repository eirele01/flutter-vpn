# Proguard Rules for BaganiVPN
# Add any specific keep rules here if your release build strips too much code.

# Keep Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }

# Keep OpenVPN native libraries
-keep class id.laskarmedia.openvpn_flutter.** { *; }

# Keep Flutter embedding
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Models for generic serialization (if strictly needed, though Hive usually handles this)

# Fix R8 Missing Class Warnings for Play Core (used by Flutter deferred components)
-dontwarn com.google.android.play.core.**
