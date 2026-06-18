import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/budget_provider.dart';
import '../widgets/category_chart.dart';
import 'add_expense_screen.dart';
import 'expense_list_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseProvider);
    final currencyAsync = ref.watch(currencyProvider);
    final budgetAsync = ref.watch(budgetProvider);
    final currencyCode = currencyAsync.value ?? 'USD';
    final currencySymbol = availableCurrencies[currencyCode] ?? '\$';
    final currencyFormat = NumberFormat.currency(symbol: currencySymbol);
    final budget = budgetAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spendly'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statistics',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: expensesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Loading expenses'),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(error.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(expenseProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (expenses) {
          final now = DateTime.now();
          final thisMonthExpenses = expenses
              .where(
                (e) => e.date.month == now.month && e.date.year == now.year,
              )
              .toList();
          final total = thisMonthExpenses.fold(
            0.0,
            (sum, e) => sum + e.amount,
          );
          final budgetProgress =
              budget != null && budget > 0 ? (total / budget).clamp(0.0, 1.0) : null;
          final budgetExceeded = budget != null && total > budget;

          return RefreshIndicator(
            onRefresh: () => ref.read(expenseProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This Month',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormat.format(total),
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${thisMonthExpenses.length} expenses',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (budget != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Budget: ${currencyFormat.format(budget)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                budgetExceeded
                                    ? 'Over budget!'
                                    : '${currencyFormat.format(budget - total)} left',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: budgetExceeded
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: budgetProgress,
                              minHeight: 10,
                              backgroundColor: Colors.white38,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                budgetExceeded ? Colors.red : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (thisMonthExpenses.isNotEmpty) ...[
                  CategoryChart(expenses: thisMonthExpenses),
                  const SizedBox(height: 24),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Expenses',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ExpenseListScreen(expenses: expenses),
                          ),
                        );
                      },
                      child: const Text('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (expenses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No expenses yet.\nTap + to add your first one.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...expenses.take(5).map(
                        (expense) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(expense.category[0]),
                            ),
                            title: Text(expense.title),
                            subtitle: Text(
                              '${expense.category} · ${DateFormat.yMMMd().format(expense.date)}',
                            ),
                            trailing: Text(
                              currencyFormat.format(expense.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Semantics(
        label: 'Add new expense',
        button: true,
        child: FloatingActionButton(
          onPressed: () async {
            final newExpense = await Navigator.of(context).push<Expense>(
              MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
            );
            if (newExpense != null) {
              if (context.mounted) {
                ref.read(expenseProvider.notifier).addExpense(
                      title: newExpense.title,
                      amount: newExpense.amount,
                      category: newExpense.category,
                      date: newExpense.date,
                      note: newExpense.note,
                    );
              }
            }
          },
          child: const Icon(Icons.add, semanticLabel: 'Add expense'),
        ),
      ),
    );
  }
}