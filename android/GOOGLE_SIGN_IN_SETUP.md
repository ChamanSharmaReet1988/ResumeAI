# Google Sign-In (Android) — Firebase SHA-1 setup

Google Drive backup uses Google Sign-In on Android. Sign-in fails with
**ApiException 10 (DEVELOPER_ERROR)** or a generic error when the app's
**signing certificate SHA-1** is not registered in Firebase for package
`com.quickresume`.

## Which SHA-1 to register

| Build type | Keystore | When it is used |
|------------|----------|-----------------|
| **Debug** | `~/.android/debug.keystore` | `flutter run`, Android Studio Run, profile builds |
| **Release / upload** | `android/upload-keystore.jks` (alias `upload`) | Release APK/AAB signed with your upload key |

Register **both** in Firebase if you test debug and release builds.

If the app is on Google Play with **Play App Signing**, also add the
**App signing key certificate** SHA-1 from Play Console → Setup → App
integrity (for production installs from Play). The **Upload key certificate**
SHA-1 should match your `upload-keystore.jks`.

## Current fingerprints (this machine)

These were verified with `./gradlew signingReport` and `keytool`:

| Keystore | SHA-1 |
|----------|-------|
| Debug | `50:28:8D:09:5B:1E:03:95:A2:79:C7:AA:F2:A6:77:82:86:56:B0:80` |
| Upload (release) | `D4:F3:1C:EF:4C:87:E5:B7:5C:A4:52:31:F4:9E:D3:DC:48:AF:B5:6A` |

`android/app/google-services.json` currently lists only:

`FB:9A:6C:D3:51:2C:21:95:90:2C:E8:40:A3:1E:21:39:53:DF:46:8C`

That fingerprint does **not** match the debug or upload keystores above (likely
an old machine or keystore). Add the debug and upload SHA-1s below.

## Add SHA-1 in Firebase

1. Open [Firebase Console](https://console.firebase.google.com/) → project
   **resumeapp-be8a3**.
2. Project settings → Your apps → Android app **com.quickresume**.
3. Under **SHA certificate fingerprints**, add each SHA-1 (debug + upload +
   Play signing key if applicable).
4. Download the updated **google-services.json** and replace
   `android/app/google-services.json`.
5. Rebuild the app (`flutter clean && flutter run` or release build).

## Verify locally

From the `android/` directory (Java 11+ required):

```bash
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
./gradlew signingReport
```

Upload keystore (password from `android/key.properties`):

```bash
keytool -list -v \
  -keystore android/upload-keystore.jks \
  -alias upload \
  -storepass '<storePassword from key.properties>'
```

## Code configuration (already in repo)

- `GoogleSignIn.initialize(serverClientId: …)` in `lib/main.dart` uses the
  **Web client** ID from the same Firebase project.
- `google-services.json` must contain matching `oauth_client` entries after
  SHA-1 registration (Android client + Web client type 3).

No code change can fix a missing SHA-1; Firebase must list every certificate
you sign with.
