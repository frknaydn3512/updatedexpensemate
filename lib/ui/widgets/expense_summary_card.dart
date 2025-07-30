import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../services/currency_service.dart';

class ExpenseSummaryCard extends StatelessWidget {
  final double totalAmount;
  final String currency;

  const ExpenseSummaryCard({super.key, required this.totalAmount, required this.currency});

  @override
  Widget build(BuildContext context) {
    // Convert amount to selected currency
    final convertedAmount = CurrencyService.convertAmount(totalAmount, currency);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Yatayda biraz boşluk, dikeyde az boşluk
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Padding değerini küçülttük
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.totalExpense,
              style: TextStyle(
                fontSize: 16, // Font boyutunu küçülttük
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6), // Boşluğu azalttık
            Text(
              CurrencyService.formatAmount(convertedAmount, currency),
              style: const TextStyle(
                fontSize: 20, // Font boyutunu küçülttük
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 