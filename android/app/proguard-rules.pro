# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# ============================================
# Flutter and Dart specific rules
# ============================================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# ============================================
# Flutter Local Notifications
# ============================================
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# ============================================
# Gson (Required for notification data serialization)
# ============================================
-keepattributes Signature
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }

# ============================================
# Java Desugaring (j$.util)
# ============================================
-dontwarn j$.util.**
-keep class j$.util.** { *; }

# ============================================
# Audio service classes (required for audio playback)
# ============================================
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.audioservice.AudioService { *; }
-keep class com.ryanheise.audioservice.AudioServiceActivity { *; }
-keep class com.ryanheise.audioservice.MediaButtonReceiver { *; }
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.ryanheise.audio_session.** { *; }

# ============================================
# Firebase rules
# ============================================
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firebase Auth
-keep class com.google.firebase.auth.** { *; }
-keep class com.google.android.gms.internal.firebase-auth-api.** { *; }

# Firebase Firestore
-keep class com.google.firebase.firestore.** { *; }
-keep class com.google.cloud.firestore.** { *; }

# Firebase Analytics
-keep class com.google.firebase.analytics.** { *; }
-keep class com.google.android.gms.measurement.** { *; }

# Firebase Crashlytics
-keep class com.google.firebase.crashlytics.** { *; }
-keep class com.crashlytics.** { *; }

# ============================================
# Google Sign-In rules
# ============================================
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.api.client.** { *; }
-dontwarn com.google.android.gms.**

# ============================================
# Network and HTTP libraries
# ============================================
# Dio - only keep what's necessary
-keep class dio.** { *; }
-keep interface dio.** { *; }
-dontwarn dio.**

# OkHttp - keep only necessary classes
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# ============================================
# Native methods (required for JNI)
# ============================================
-keepclasseswithmembernames class * {
    native <methods>;
}

# ============================================
# Annotations
# ============================================
-keep @androidx.annotation.Keep class * { *; }
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}

# ============================================
# Serialization
# ============================================
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ============================================
# Enums
# ============================================
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ============================================
# Parcelable
# ============================================
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# ============================================
# Android resources
# ============================================
-keep class **.R
-keep class **.R$* {
    <fields>;
}

# ============================================
# Application class (if custom)
# ============================================
-keep class com.tilawa.app.MainActivity { *; }
-keep class com.tilawa.app.MainActivity$* { *; }

# ============================================
# Obfuscation optimizations
# ============================================
# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Remove debug information
-assumenosideeffects class kotlin.jvm.internal.Intrinsics {
    static void checkParameterIsNotNull(java.lang.Object, java.lang.String);
}

# ============================================
# Credential Manager
# ============================================
-keep class androidx.credentials.** { *; }
-dontwarn androidx.credentials.**

# ============================================
# MultiDex
# ============================================
-keep class androidx.multidex.** { *; }
-dontwarn androidx.multidex.**



