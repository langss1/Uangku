# Flutter Obfuscation rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }
-keep class io.flutter.scheduler.** { *; }

# Keep native methods of plugins intact
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep sqlite database classes intact
-keep class net.sqlcipher.** { *; }
-keep class sqflite.** { *; }

# Google ML Kit and Text Recognition rules
-dontwarn com.google.mlkit.**
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }

# Ignore missing Play Core splitcompat and splitinstall dependencies
-dontwarn com.google.android.play.core.**

# Prevent shrinking of serialized network models
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
