# Google Sign-In Setup Guide

## Issue
You're getting the error: `GoogleSignInException (GoogleSignInException(code GoogleSignInExceptionCode.clientConfigurationError, serverClientId must be provided on Android, null))`

## Solution

### 1. Get Your Server Client ID from Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Project Settings** (gear icon)
4. Scroll down to **Your apps** section
5. Find your **Web app** (or create one if it doesn't exist)
6. Copy the **Web client ID** (it looks like: `123456789-abcdefghijklmnop.apps.googleusercontent.com`)

### 2. Update the Configuration

Open `lib/core/config/google_sign_in_config.dart` and replace `YOUR_SERVER_CLIENT_ID_HERE` with your actual Web client ID:

```dart
class GoogleSignInConfig {
  static const String serverClientId = 'YOUR_ACTUAL_WEB_CLIENT_ID_HERE';
}
```

### 3. Alternative: Use Environment Variables (Recommended for Production)

For better security, you can use environment variables:

1. Create a `.env` file in your project root:
```
GOOGLE_SERVER_CLIENT_ID=your_actual_web_client_id_here
```

2. Add `flutter_dotenv` to your `pubspec.yaml`:
```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

3. Update the config file:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleSignInConfig {
  static String get serverClientId => dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '';
}
```

4. Load the environment in `main.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // ... rest of your main function
}
```

### 4. Android Configuration

Make sure your `android/app/google-services.json` file is properly configured with your Firebase project.

### 5. iOS Configuration (if needed)

For iOS, you might need to add the GoogleService-Info.plist file to your iOS project.

## Testing

After updating the configuration:

1. Clean your project: `flutter clean`
2. Get dependencies: `flutter pub get`
3. Run the app: `flutter run`

The Google Sign-In should now work properly without the client configuration error.

## Troubleshooting

- Make sure you're using the **Web client ID**, not the Android client ID
- Ensure your Firebase project has Google Sign-In enabled
- Check that your app's package name matches the one in Firebase Console
- Verify that the `google-services.json` file is in the correct location
