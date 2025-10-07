# Firebase Setup Guide

## Overview
This guide will help you populate your Firebase Firestore database with subscription plans and set up the necessary data structure for the Muzakri app.

## Prerequisites
- Firebase project created
- `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) files added to your project
- Firebase dependencies added to `pubspec.yaml`

## Quick Setup

### 1. Run the Firebase Data Initialization Script

```bash
# Make the script executable
chmod +x scripts/init_firebase_data.dart

# Run the initialization script
dart scripts/init_firebase_data.dart
```

### 2. Alternative: Initialize from within the app

You can also initialize Firebase data from within your app by calling the initialization service:

```dart
// In your main.dart or wherever you initialize your app
final firebaseInitService = sl<FirebaseInitializationService>();
await firebaseInitService.initializeFirebaseData();
```

## What Gets Created

### 1. Subscription Plans Collection
The script creates 5 subscription plans in the `subscription_plans` collection:

- **Monthly Basic** ($4.99/month)
- **Monthly Premium** ($7.99/month) - Most Popular
- **Yearly Basic** ($47.99/year) - 20% discount
- **Yearly Premium** ($67.99/year) - 30% discount
- **Lifetime Access** ($99.99 one-time) - 50% discount

### 2. Data Structure

#### Subscription Plans
```json
{
  "id": "monthly_premium",
  "name": "Monthly Premium",
  "description": "Best value monthly plan with all features",
  "price": 7.99,
  "currency": "USD",
  "type": "monthly",
  "durationInDays": 30,
  "features": [
    "Everything in Basic",
    "Exclusive reciters",
    "Advanced audio controls",
    "Cloud sync",
    "Early access to new features"
  ],
  "isPopular": true,
  "discountPercentage": null,
  "order": 2
}
```

#### User Premium Status
```json
{
  "isPremium": false,
  "subscriptionStartDate": null,
  "subscriptionEndDate": null,
  "subscriptionType": null,
  "isTrialUsed": false,
  "trialStartDate": null,
  "trialEndDate": null,
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

## Firebase Console Verification

After running the script, you can verify the data in your Firebase Console:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Firestore Database**
4. You should see:
   - `subscription_plans` collection with 5 documents
   - `users` collection (empty initially, will be populated when users sign up)

## Testing the Setup

### 1. Check Subscription Plans
```dart
final subscriptionPlansService = sl<SubscriptionPlansService>();
final plans = await subscriptionPlansService.getSubscriptionPlans();
print('Found ${plans.length} subscription plans');
```

### 2. Check Firebase Stats
```dart
final firebaseInitService = sl<FirebaseInitializationService>();
final stats = await firebaseInitService.getFirebaseDataStats();
print('Subscription Plans: ${stats['subscription_plans']}');
```

## Troubleshooting

### Common Issues

1. **Firebase not initialized**
   - Make sure you've run `Firebase.initializeApp()` before calling the initialization service

2. **Permission denied**
   - Check your Firestore security rules
   - Make sure your Firebase project has the correct configuration

3. **Script fails to run**
   - Ensure all dependencies are installed: `flutter pub get`
   - Check that your Firebase configuration files are in place

### Firestore Security Rules

Make sure your Firestore security rules allow reading/writing:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read access to subscription plans
    match /subscription_plans/{document} {
      allow read: if true;
    }
    
    // Allow users to read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /premium/{document} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      match /purchases/{document} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

## Advanced Configuration

### Custom Subscription Plans

You can modify the subscription plans by editing the `_getDefaultSubscriptionPlans()` method in `SubscriptionPlansService`:

```dart
List<SubscriptionPlan> _getDefaultSubscriptionPlans() {
  return [
    // Add your custom plans here
    SubscriptionPlan(
      id: 'custom_plan',
      name: 'Custom Plan',
      description: 'Your custom description',
      price: 9.99,
      currency: 'USD',
      type: SubscriptionType.monthly,
      durationInDays: 30,
      features: ['Feature 1', 'Feature 2'],
      isPopular: false,
      discountPercentage: null,
      order: 6,
    ),
  ];
}
```

### Environment-Specific Data

You can create different data sets for different environments:

```dart
// Development
if (kDebugMode) {
  await _addDevelopmentPlans();
} else {
  await _addProductionPlans();
}
```

## Next Steps

1. **Test the premium features** in your app
2. **Set up payment processing** (Stripe, Google Play, App Store)
3. **Configure push notifications** for subscription updates
4. **Add analytics** to track subscription metrics

## Support

If you encounter any issues:

1. Check the Firebase Console for error logs
2. Verify your Firebase project configuration
3. Ensure all dependencies are properly installed
4. Check the Flutter and Firebase documentation

Happy coding! 🚀