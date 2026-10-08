# ReactMaster

Offline-first Flutter app for learning modern **React** and **Next.js**: structured lessons, 150 interview questions and 250 randomized MCQs, with XP, levels, streaks, achievements, bookmarks, search, dark mode and AdMob.

The app name lives in `lib/core/constants/app_constants.dart` (`AppConstants.appName`).

## Stack
Flutter 3.41 / Dart 3.11 · Riverpod 3 · GoRouter · Hive CE · google_mobile_ads (UMP consent) · Material 3

## Structure
```
lib/
  core/        constants (AppConstants, AdConfig), theme, router, services (storage, ads, subscription), utils
  data/        models, datasources (bundled JSON), repositories (+ providers)
  features/    home, learn, interview, quiz, progress, achievements, bookmarks, search, daily_challenge, profile, settings
  shared/      widgets (CodeBlock, syntax highlighter, celebrations, banner ad, ...)
assets/data/   react_lessons.json, next_lessons.json, interview_questions.json, mcq_questions.json
```
Content is plain JSON; add lessons or questions without touching Dart code. `test/unit/bundled_content_test.dart` validates counts, ids, option counts and answer indexes.

## Commands
```sh
flutter analyze
flutter test
flutter run
```

## Release checklist
1. **Application ID:** change `applicationId` in `android/app/build.gradle.kts` and the iOS bundle id (you can't change it after publishing).
2. **Signing:** create an upload keystore and `android/key.properties` (git-ignored):
   `storePassword=… keyPassword=… keyAlias=upload storeFile=/abs/path/upload-keystore.jks`
3. **AdMob app IDs:** pass `-PADMOB_APP_ID=ca-app-pub-…~…` to Gradle (or set it in `android/gradle.properties`); replace `GADApplicationIdentifier` in `ios/Runner/Info.plist`. Both default to Google's **test** IDs.
4. **Ad unit IDs:** copy `config/admob.example.json` to `config/admob.json` (git-ignored), fill it in, and build with
   `flutter build appbundle --release --dart-define-from-file=config/admob.json`.
   Debug/profile builds always use test ads.
5. Replace the placeholder **privacy policy / terms** (`lib/features/profile/presentation/info_screens.dart`), host the policy at a public URL, and set `AppConstants.supportEmail`.
6. Configure the consent message (GDPR/US states) in the AdMob console's *Privacy & messaging* section.

## Notes
- iOS: google_mobile_ads 9.1.0 needs `CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES` (set in `ios/Flutter/*.xcconfig` and the Podfile), and SwiftPM is disabled for this project in `pubspec.yaml`. Revisit both when upgrading the plugin.
- Premium is abstracted behind `SubscriptionService` (free tier only; no payments implemented).
