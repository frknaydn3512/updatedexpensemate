import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  static const Map<String, double> _exchangeRates = {
    '₺': 1.0,    // TRY - Base currency
    '\$': 0.031,  // USD - 1 TRY = 0.031 USD (approx)
    '€': 0.029,   // EUR - 1 TRY = 0.029 EUR (approx)
    '£': 0.025,   // GBP - 1 TRY = 0.025 GBP (approx)
  };

  // Convert amount from TRY to target currency
  static double convertAmount(double amountInTRY, String targetCurrency) {
    if (targetCurrency == '₺') {
      return amountInTRY; // No conversion needed for TRY
    }
    
    final rate = _exchangeRates[targetCurrency];
    if (rate == null) {
      return amountInTRY; // Fallback to original amount
    }
    
    return amountInTRY * rate;
  }

  // Convert amount from any currency back to TRY
  static double convertToTRY(double amount, String fromCurrency) {
    if (fromCurrency == '₺') {
      return amount; // No conversion needed for TRY
    }
    
    final rate = _exchangeRates[fromCurrency];
    if (rate == null) {
      return amount; // Fallback to original amount
    }
    
    return amount / rate;
  }

  // Get exchange rate for a currency
  static double getExchangeRate(String currency) {
    return _exchangeRates[currency] ?? 1.0;
  }

  // Get all available currencies
  static List<String> getAvailableCurrencies() {
    return _exchangeRates.keys.toList();
  }

  // Format amount with currency symbol
  static String formatAmount(double amount, String currency) {
    return "${amount.toStringAsFixed(2)}$currency";
  }
} 