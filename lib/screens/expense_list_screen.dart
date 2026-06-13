import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';

class ExpenseListScreen extends StatefulWidget {
  final List<Expense> expenses;

  const ExpenseListScreen({super.key, required this.expenses});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  String? _selectedCategory;

  List<String> get _categories {
    final cats = widget.expenses.map((e) => e.category).toSet().toList();
    cats.sort();
    return cats;
  }

  List<Expense> get _filteredExpenses {
    if (_selectedCategory == null) return widget.expenses;
    return widget.expenses
        .where((e) => e.category == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final filtered = _filteredExpenses;

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
              child: ListView(
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
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No expenses in this category.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final expense = filtered[index];
                      return Card(
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}