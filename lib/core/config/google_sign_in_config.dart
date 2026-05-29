/// Google Cloud project: `resumeapp-496318`
///
/// iOS OAuth client ID (type: iOS). Android also needs a **Web application**
/// OAuth client ID for [serverClientId] if `google-services.json` has no
/// `oauth_client` entries — create one in the same project and paste it here.
abstract final class GoogleSignInConfig {
  static const String iosClientId =
      '48903946368-qbqg3as76gkf99cbbi4b59ji8474tnso.apps.googleusercontent.com';

  /// Web client ID from Google Cloud Console (Android / server token flow).
  static const String androidServerClientId =
      '84500423167-5is6rbbks07npmbek8f55qkgknsljttp.apps.googleusercontent.com';
}
