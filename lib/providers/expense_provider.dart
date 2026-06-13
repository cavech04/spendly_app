import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';

class ExpenseNotifier extends StateNotifier<List<Expense>> {
  ExpenseNotifier() : super(_initialExpenses);

  static final List<Expense> _initialExpenses = [
    Expense(
      id: '1',
      title: 'Groceries',
      amount: 42.50,
      category: 'Food',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Expense(
      id: '2',
      title: 'Bus ticket',
      amount: 2.80,
      category: 'Transport',
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Expense(
      id: '3',
      title: 'Coffee',
      amount: 3.20,
      category: 'Food',
      date: DateTime.now(),
    ),
  ];

  void addExpense(Expense expense) {
    state = [expense, ...state];
  }

  double get totalThisMonth =>
      state.fold(0, (sum, e) => sum + e.amount);
}

final expenseProvider =
    StateNotifierProvider<ExpenseNotifier, List<Expense>>((ref) {
  return ExpenseNotifier();
});