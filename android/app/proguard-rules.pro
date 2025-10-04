# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Keep audio service classes
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.audioservice.AudioService { *; }
-keep class com.ryanheise.audioservice.AudioServiceActivity { *; }
-keep class com.ryanheise.audioservice.MediaButtonReceiver { *; }

# Keep just_audio classes
-keep class com.ryanheise.just_audio.** { *; }

# Keep audio session classes
-keep class com.ryanheise.audio_session.** { *; }

# Keep Flutter audio service
-keep class io.flutter.plugins.audioservice.** { *; }

# Keep Dio classes for network requests
-keep class dio.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Keep model classes
-keep class com.example.muzakri.** { *; }

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep all classes that have @Keep annotation
-keep @androidx.annotation.Keep class * { *; }
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}

# Keep serialization classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable classes
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep R classes
-keep class **.R
-keep class **.R$* {
    <fields>;
}

# Keep all classes in the main package
-keep class com.example.muzakri.** { *; }
