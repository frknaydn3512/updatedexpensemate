import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../data/database/app_database.dart';
import '../../services/currency_service.dart';


class ExpenseList extends StatelessWidget {
  final List<Expense> expenses;
  final String currency;
  final Function(Expense) onEditExpense;
  final Function(Expense) onDeleteExpense;

  const ExpenseList({
    super.key,
    required this.expenses,
    required this.currency,
    required this.onEditExpense,
    required this.onDeleteExpense,
  });

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return _ExpenseListItem(
          expense: expense,
          currency: currency,
          onEdit: () => onEditExpense(expense),
          onDelete: () => onDeleteExpense(expense),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Image.asset('assets/lottie/empty.json'),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noExpenses,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Hadi ilk harcamanı ekle!',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ExpenseListItem extends StatelessWidget {
  final Expense expense;
  final String currency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseListItem({
    required this.expense,
    required this.currency,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6366F1).withOpacity(0.8),
                const Color(0xFF8B5CF6).withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.payments, color: Colors.white, size: 16),
        ),
        title: Text(
          expense.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF1F2937),
          ),
        ),
        subtitle: Text(
          "${expense.category} • ${expense.date.toLocal().toString().split(' ')[0]}",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            CurrencyService.formatAmount(
              CurrencyService.convertAmount(expense.amount, currency),
              currency
            ),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF6366F1),
            ),
          ),
        ),
        onTap: onEdit,
        onLongPress: () => _showDeleteDialog(context),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(localizations.deleteConfirmTitle),
        content: Text(localizations.deleteConfirmContent(expense.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx, true);
              onDelete();
            },
            child: Text(localizations.delete),
          ),
        ],
      ),
    );
  }
} 