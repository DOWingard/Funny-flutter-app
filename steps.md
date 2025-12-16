# iOS Launch Readiness Steps

## 1. AdMob Configuration

### Replace App ID
1. Open `ios/Runner/Info.plist`.
2. Locate the `GADApplicationIdentifier` key.
3. Replace the test ID `ca-app-pub-3940256099942544~3347511713` with your **Production AdMob App ID**.

### Replace Unit IDs
1. Open `lib/youcantcopymymain.dart` (or wherever ads are initialized/loaded).
2. Replace any test unit IDs (e.g., `ca-app-pub-3940256099942544/6300978111`) with your **Production AdMob Unit IDs**.

### SKAdNetwork (Crucial for Ad Revenue)
Ensure you update `ios/Runner/Info.plist` with the latest `SKAdNetworkItems`. Google's is:
```xml
<key>SKAdNetworkItems</key>
<array>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>cstr6suwn9.skadnetwork</string>
  </dict>
  <!-- Add other network identifiers here -->
</array>
```
*Note: `NSUserTrackingUsageDescription` has been added to your Info.plist. You may want to customize the message.*

## 2. Environment Variables (.env)

A `.env` file has been created for you. Fill in the following values:

- `ADMOB_APP_ID`: Your AdMob App ID.
- `ADMOB_BANNER_ID`: Your AdMob Banner Unit ID.
- `ADMOB_INTERSTITIAL_ID`: Your AdMob Interstitial Unit ID (if applicable).

*Note: To use these in your Flutter app, you may need to add `flutter_dotenv` to your `pubspec.yaml` and update your code to read from `.env`, or use `--dart-define` during build.*

## 3. CI/CD Setup (GitHub Actions + Fastlane)

### Prerequisites
> [!IMPORTANT]
> Since you are on **Linux**, you cannot run Fastlane for iOS locally to build the app. You **MUST** use the GitHub Actions pipeline (which runs on macOS) to build and deploy.
>
> **Fastlane is already configured** in this repo (`ios/fastlane/Fastfile`). You do NOT need to run `fastlane init`.
>
> Your only task is to provide the credentials (Secrets) so the CI can do the work.

- **Apple Developer Account**: You need a paid account.
- **App Store Connect API Key**: Create one in App Store Connect > Users and Access > Keys.

### GitHub Secrets
Go to your GitHub Repository > Settings > Secrets and Variables > Actions, and add the following:

- `APP_STORE_CONNECT_API_KEY_KEY_ID`: Your App Store Connect Key ID.
- `APP_STORE_CONNECT_API_KEY_ISSUER_ID`: Your App Store Connect Issuer ID.
- `APP_STORE_CONNECT_API_KEY_CONTENT`: The content of your `.p8` API key file.
- `MATCH_PASSWORD`: A password to encrypt your certificates/profiles (if using Fastlane Match).
- `MATCH_GIT_URL`: URL of a private git repo to store certificates (if using Fastlane Match).

### How to get these values:
1.  Go to [App Store Connect](https://appstoreconnect.apple.com/).
2.  Navigate to **Users and Access** > **Integrations** > **Team Keys**.
3.  Click the **+** button to generate a new key.
    *   **Name**: "GitHub Actions" (or similar).
    *   **Access**: "App Manager" or "Admin".
4.  **Download the API Key (.p8 file)**.
    *   *Warning: You can only download this ONCE. Save it safely.*
    *   Open the `.p8` file with a text editor. The contents (starting with `-----BEGIN PRIVATE KEY-----`) is your `APP_STORE_CONNECT_API_KEY_CONTENT`.
5.  **Key ID**: Displayed in the table next to your new key. This is your `APP_STORE_CONNECT_API_KEY_KEY_ID`.
6.  **Issuer ID**: Displayed at the top of the page (e.g., `57246542-96fe-1a63-e053-0824d011072a`). This is your `APP_STORE_CONNECT_API_KEY_ISSUER_ID`.

### Fastlane Configuration
The `ios/fastlane/Fastfile` and `Appfile` have been created.
1. Update `Appfile` with your `app_identifier` and `apple_id`.
2. Review `Fastfile` to ensure the `build_app` and `upload_to_testflight` steps match your needs.

## 4. Launch
1. Commit and push your changes.
2. The GitHub Action `ios_deploy` will trigger on push to `main` (or manually).
3. Check the Actions tab in GitHub for progress.
4. Once successful, check TestFlight in App Store Connect.
