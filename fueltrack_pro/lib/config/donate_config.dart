/// Donation identifiers — shared with Wealth Journal (Melmidalam Apps).
class DonateConfig {
  static const String upiId = 'wealthjournal@ybl';
  static const String upiPayeeName = 'Melmidalam Apps';
  static const String upiNote = 'FuelTrack Pro donation';

  static const String paypalUrl = 'https://paypal.me/thankathurai';

  static Uri get paypalProfileUri => Uri.parse(paypalUrl);

  static const String btcAddress =
      'bc1qfmrt92j05u56yueahs42ujz8qtcmcw5a0apyyp';
  static const String erc20Address =
      '0x07d5922568b0047f7A700497b7d5eaf364c0A538';
  static const String solanaAddress =
      'Ebr9tSd4bTKgUZEDNHUycVEkwdfxmpGLvqjy6zLXmfkq';

  static const String termsUrl = 'https://melmidalamapps.fyi/terms/';

  static Uri get termsUri => Uri.parse(termsUrl);

  static const List<int> presetAmounts = [49, 99, 199, 499, 999];
  static const int defaultAmount = 99;
  static const int minimumAmount = 10;
}

String buildUpiDeepLink({
  required String upiId,
  required String payeeName,
  required int amount,
  required String note,
}) {
  return Uri(
    scheme: 'upi',
    host: 'pay',
    queryParameters: <String, String>{
      'pa': upiId,
      'pn': payeeName,
      'am': amount.toString(),
      'cu': 'INR',
      'tn': note,
    },
  ).toString();
}

Uri cryptoWalletUri({required bool bitcoin, required String address}) {
  final a = address.trim();
  if (bitcoin) return Uri.parse('bitcoin:$a');
  return Uri.parse('ethereum:$a');
}

Uri solanaWalletUri(String address) => Uri.parse('solana:${address.trim()}');
