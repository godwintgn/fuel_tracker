/// Web client ID from Google Cloud Console (OAuth 2.0 → Web application).
/// Build: `--dart-define=GOOGLE_OAUTH_SERVER_CLIENT_ID=xxx.apps.googleusercontent.com`
const String kGoogleOAuthServerClientId = String.fromEnvironment(
  'GOOGLE_OAUTH_SERVER_CLIENT_ID',
  defaultValue: '',
);
