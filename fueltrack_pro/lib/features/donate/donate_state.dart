enum DonateMethod { upi, paypal, crypto }

String presetSecondaryLabel(int amount) {
  return switch (amount) {
    49 => 'coffee',
    99 => 'popular',
    199 => 'generous',
    499 => 'super fan',
    999 => 'legend',
    _ => '',
  };
}
