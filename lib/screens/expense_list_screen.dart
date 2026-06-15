import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';

class ExpenseListScreen extends ConsumerWidget {
  final List<Expense> expenses;

  const ExpenseListScreen({super.key, required this.expenses});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final expensesAsync = ref.watch(expenseProvider);
    final currentExpenses = expensesAsync.value ?? expenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Expenses'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: 40,
              child: _CategoryFilter(expenses: currentExpenses),
            ),
          ),
          Expanded(
            child: _ExpenseList(
              expenses: currentExpenses,
              currencyFormat: currencyFormat,
              onDelete: (id) {
                ref.read(expenseProvider.notifier).deleteExpense(id);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilter extends StatefulWidget {
  final List<Expense> expenses;

  const _CategoryFilter({required this.expenses});

  @override
  State<_CategoryFilter> createState() => _CategoryFilterState();
}

class _CategoryFilterState extends State<_CategoryFilter> {
  String? _selectedCategory;

  List<String> get _categories {
    final cats = widget.expenses.map((e) => e.category).toSet().toList();
    cats.sort();
    return cats;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: const Text('All'),
            selected: _selectedCategory == null,
            onSelected: (_) {
              setState(() => _selectedCategory = null);
            },
          ),
        ),
        ..._categories.map((cat) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(cat),
                selected: _selectedCategory == cat,
                onSelected: (_) {
                  setState(() => _selectedCategory = cat);
                },
              ),
            )),
      ],
    );
  }
}

class _ExpenseList extends StatelessWidget {
  final List<Expense> expenses;
  final NumberFormat currencyFormat;
  final void Function(String id) onDelete;

  const _ExpenseList({
    required this.expenses,
    required this.currencyFormat,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const Center(child: Text('No expenses in this category.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return Dismissible(
          key: Key(expense.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) {
            onDelete(expense.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${expense.title} deleted'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(expense.category[0]),
              ),
              title: Text(expense.title),
              subtitle: Text(
                '${expense.category} · ${DateFormat.yMMMd().format(expense.date)}'
                '${expense.note != null ? '\n${expense.note}' : ''}',
              ),
              isThreeLine: expense.note != null,
              trailing: Text(
                currencyFormat.format(expense.amount),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }
}