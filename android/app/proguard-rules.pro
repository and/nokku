# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep video player classes
-keep class com.google.android.exoplayer2.** { *; }

# Keep device admin classes
-keep class com.safegallery.DeviceAdminReceiver { *; }

# Keep Play Core classes (to fix R8 errors)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**