# Tilawa

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Building Secure Android Release

This project is configured with secure build settings including:

- **Code obfuscation** (R8/ProGuard)
- **Resource shrinking** (removes unused resources)
- **Code minification** (reduces APK size)
- **Log removal** (removes debug logs in release builds)

### Setting Up App Signing

1. **Create a keystore** (if you don't have one):

   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **Create key.properties file**:

   - Copy `android/key.properties.template` to `android/key.properties`
   - Fill in your keystore information:
     ```
     storePassword=YOUR_KEYSTORE_PASSWORD
     keyPassword=YOUR_KEY_PASSWORD
     keyAlias=YOUR_KEY_ALIAS
     storeFile=/path/to/your/keystore.jks
     ```

3. **Build release APK**:

   ```bash
   flutter build apk --release
   ```

4. **Build release App Bundle** (for Google Play):
   ```bash
   flutter build appbundle --release
   ```

### Security Features Enabled

- ✅ Code obfuscation with R8 full mode
- ✅ Resource shrinking
- ✅ Code minification
- ✅ Debug information removal
- ✅ Log statement removal in release builds
- ✅ ProGuard rules for Firebase, Flutter, and dependencies

**Important**: Never commit `key.properties` or `.keystore`/`.jks` files to version control. They are already in `.gitignore`.
