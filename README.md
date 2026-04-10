# Grocery List App

Grocery List App helps you manage shopping lists, pantry inventory, and barcode-based item entry in one Flutter app.

## Key Features

- Create and organize grocery lists by category.
- Track pantry inventory, quantities, locations, and expiration dates.
- Scan barcodes to quickly add items to your grocery list or pantry.

## Setup

1. Run `flutter pub get`.
2. Start the app with `flutter run`.

## Android Release Signing

Before submitting to the Play Store, generate a real release keystore and update `android/key.properties`.

1. Generate a keystore with `keytool`:

```bash
keytool -genkeypair -v \
  -keystore your-release-key.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias grocerylist
```

2. Update `android/key.properties` with the real values:

```properties
storePassword=YOUR_ACTUAL_STORE_PASSWORD
keyPassword=YOUR_ACTUAL_KEY_PASSWORD
keyAlias=grocerylist
storeFile=../your-release-key.jks
```

3. Keep the `.jks` file and `android/key.properties` out of source control.
4. Run `flutter build appbundle --release` or `flutter build apk --release` after the keystore is in place.

If `android/key.properties` exists but points to a placeholder or missing keystore, the release build will fail. That is expected and prevents shipping an unsigned artifact by mistake.

## Project Structure

- `lib/app.dart`: app-level providers and router entry.
- `lib/core/`: shared constants, theme, router, and utilities.
- `lib/features/grocery_list/`: grocery list models, blocs, pages, and widgets.
- `lib/features/pantry/`: pantry inventory models, blocs, pages, and widgets.
- `lib/features/scanner/`: barcode scanner flows and scanner UI.
- `web/` and `android/`: platform-specific metadata and build configuration.

## Requirements

- Flutter SDK installed and available on your PATH.
- Android SDK for Android builds and emulator/device deployment.
- Camera permission enabled on devices that use the barcode scanner.
