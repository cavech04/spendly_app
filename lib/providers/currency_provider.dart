import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _currencies = {
  'USD': '\$',
  'EUR': '€',
  'GBP': '£',
  'PLN': 'zł',
  'JPY': '¥',
  'CAD': 'C\$',
  'CHF': 'CHF',
};

Map<String, String> get availableCurrencies => _currencies;

class CurrencyNotifier extends AsyncNotifier<String> {
  static const _storage = FlutterSecureStorage();
  static const _key = 'selected_currency';

  @override
  Future<String> build() async {
    final saved = await _storage.read(key: _key);
    return saved ?? 'USD';
  }

  Future<void> setCurrency(String currencyCode) async {
    await _storage.write(key: _key, value: currencyCode);
    state = AsyncData(currencyCode);
  }

  String get symbol =>
      _currencies[state.value ?? 'USD'] ?? '\$';
}

final currencyProvider =
    AsyncNotifierProvider<CurrencyNotifier, String>(CurrencyNotifier.new);