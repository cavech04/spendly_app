import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class ExpenseNotifier extends AsyncNotifier<List<Expense>> {
  late ApiService _api;

  @override
  Future<List<Expense>> build() async {
    _api = ref.read(apiServiceProvider);
    return await _api.getExpenses();
  }

  Future<void> addExpense({
    required String title,
    required double amount,
    required String category,
    required DateTime date,
    String? note,
  }) async {
    final newExpense = await _api.addExpense(
      title: title,
      amount: amount,
      category: category,
      date: date,
      note: note,
    );
    state = AsyncData([newExpense, ...state.value ?? []]);
  }

  Future<void> deleteExpense(String id) async {
    await _api.deleteExpense(id);
    state = AsyncData(
      (state.value ?? []).where((e) => e.id != id).toList(),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _api.getExpenses());
  }

  double get totalThisMonth {
    final expenses = state.value ?? [];
    final now = DateTime.now();
    return expenses
        .where((e) => e.date.month == now.month && e.date.year == now.year)
        .fold(0, (sum, e) => sum + e.amount);
  }
}

final expenseProvider =
    AsyncNotifierProvider<ExpenseNotifier, List<Expense>>(ExpenseNotifier.new);