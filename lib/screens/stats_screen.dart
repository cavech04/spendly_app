import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/currency_provider.dart';
import '../models/expense.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseProvider);
    final currencyAsync = ref.watch(currencyProvider);
    final currencyCode = currencyAsync.value ?? 'USD';
    final currencySymbol = availableCurrencies[currencyCode] ?? '\$';
    final currencyFormat = NumberFormat.currency(symbol: currencySymbol);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (expenses) {
          if (expenses.isEmpty) {
            return const Center(
              child: Text('No expenses yet to show statistics.'),
            );
          }

          final now = DateTime.now();
          final thisMonth = expenses.where(
            (e) => e.date.month == now.month && e.date.year == now.year,
          ).toList();

          final totalThisMonth =
              thisMonth.fold(0.0, (sum, e) => sum + e.amount);

          final totalAllTime =
              expenses.fold(0.0, (sum, e) => sum + e.amount);

          final avgPerDay = thisMonth.isEmpty
              ? 0.0
              : totalThisMonth / now.day;

          final categoryTotals = <String, double>{};
          for (final e in expenses) {
            categoryTotals[e.category] =
                (categoryTotals[e.category] ?? 0) + e.amount;
          }
          final topCategory = categoryTotals.entries.isEmpty
              ? null
              : categoryTotals.entries
                  .reduce((a, b) => a.value > b.value ? a : b);

          final monthlyTotals = <String, double>{};
          for (final e in expenses) {
            final key =
                '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}';
            monthlyTotals[key] = (monthlyTotals[key] ?? 0) + e.amount;
          }
          final sortedMonths = monthlyTotals.keys.toList()..sort();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'This Month',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.receipt_long,
                      label: 'Total Spent',
                      value: currencyFormat.format(totalThisMonth),
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.today,
                      label: 'Avg per Day',
                      value: currencyFormat.format(avgPerDay),
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.list_alt,
                      label: 'Expenses',
                      value: '${thisMonth.length}',
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.star,
                      label: 'Top Category',
                      value: topCategory?.key ?? '-',
                      color: Colors.pink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'All Time',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _StatCard(
                icon: Icons.account_balance_wallet,
                label: 'Total All Time',
                value: currencyFormat.format(totalAllTime),
                color: Colors.indigo,
              ),
              const SizedBox(height: 24),
              Text(
                'Monthly Breakdown',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ...sortedMonths.reversed.map((month) {
                final parts = month.split('-');
                final date = DateTime(
                  int.parse(parts[0]),
                  int.parse(parts[1]),
                );
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(DateFormat.yMMMM().format(date)),
                    trailing: Text(
                      currencyFormat.format(monthlyTotals[month]!),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}