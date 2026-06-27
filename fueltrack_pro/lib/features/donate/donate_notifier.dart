import 'package:flutter/foundation.dart';

import '../../config/donate_config.dart';
import 'donate_state.dart';

class DonateNotifier extends ChangeNotifier {
  DonateNotifier()
      : _selectedAmount = DonateConfig.defaultAmount,
        _expandedMethod = DonateMethod.upi;

  int _selectedAmount;
  DonateMethod? _expandedMethod;
  var _busyOpening = false;

  int get selectedAmount => _selectedAmount;
  DonateMethod? get expandedMethod => _expandedMethod;
  bool get busyOpening => _busyOpening;
  bool get hasValidAmount => _selectedAmount >= DonateConfig.minimumAmount;

  void applyPresetAmount(int amount) {
    _selectedAmount = amount;
    notifyListeners();
  }

  void updateAmountFromField(String digits) {
    _selectedAmount = int.tryParse(digits.trim()) ?? 0;
    notifyListeners();
  }

  void tapMethodHeader(DonateMethod method) {
    _expandedMethod = _expandedMethod == method ? null : method;
    notifyListeners();
  }

  void setOpeningBusy() {
    _busyOpening = true;
    notifyListeners();
  }

  void clearOpeningBusy() {
    _busyOpening = false;
    notifyListeners();
  }
}
