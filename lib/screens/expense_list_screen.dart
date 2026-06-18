import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/currency_provider.dart';
import 'edit_expense_screen.dart';

class ExpenseListScreen extends ConsumerWidget {
  final List<Expense> expenses;

  const ExpenseListScreen({super.key, required this.expenses});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyAsync = ref.watch(currencyProvider);
    final currencyCode = currencyAsync.value ?? 'USD';
    final currencySymbol = availableCurrencies[currencyCode] ?? '\$';
    final currencyFormat = NumberFormat.currency(symbol: currencySymbol);
    final expensesAsync = ref.watch(expenseProvider);
    final currentExpenses = expensesAsync.value ?? expenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Expenses'),
      ),
      body: _ExpenseListBody(
        expenses: currentExpenses,
        currencyFormat: currencyFormat,
        onDelete: (id) {
          ref.read(expenseProvider.notifier).deleteExpense(id);
        },
      ),
    );
  }
}

class _ExpenseListBody extends StatefulWidget {
  final List<Expense> expenses;
  final NumberFormat currencyFormat;
  final void Function(String id) onDelete;

  const _ExpenseListBody({
    required this.expenses,
    required this.currencyFormat,
    required this.onDelete,
  });

  @override
  State<_ExpenseListBody> createState() => _ExpenseListBodyState();
}

class _ExpenseListBodyState extends State<_ExpenseListBody> {
  String? _selectedCategory;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final cats = widget.expenses.map((e) => e.category).toSet().toList();
    cats.sort();
    return cats;
  }

  List<Expense> get _filteredExpenses {
    return widget.expenses.where((e) {
      final matchesCategory =
          _selectedCategory == null || e.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (e.note?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredExpenses;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search expenses...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              ? const Center(
                  child: Text('No expenses found.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final expense = filtered[index];
                    return Semantics(
                      label: 'Expense: ${expense.title}, '
                          '${widget.currencyFormat.format(expense.amount)}, '
                          '${expense.category}. Swipe left to delete. Long press to edit.',
                      child: Dismissible(
                        key: Key(expense.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            semanticLabel: 'Delete',
                          ),
                        ),
                        onDismissed: (_) {
                          widget.onDelete(expense.id);
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
                            minVerticalPadding: 12,
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
                              widget.currencyFormat.format(expense.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onLongPress: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EditExpenseScreen(expense: expense),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}