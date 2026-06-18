import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BudgetNotifier extends AsyncNotifier<double?> {
  static const _storage = FlutterSecureStorage();
  static const _key = 'monthly_budget';

  @override
  Future<double?> build() async {
    final saved = await _storage.read(key: _key);
    if (saved == null) return null;
    return double.tryParse(saved);
  }

  Future<void> setBudget(double amount) async {
    await _storage.write(key: _key, value: amount.toString());
    state = AsyncData(amount);
  }

  Future<void> clearBudget() async {
    await _storage.delete(key: _key);
    state = const AsyncData(null);
  }
}

final budgetProvider =
    AsyncNotifierProvider<BudgetNotifier, double?>(BudgetNotifier.new);