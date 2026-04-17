import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  static const String _baseUrl = 'https://open.er-api.com/v6/latest';

  // Singleton pattern
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  /// Fetches exchange rates relative to IDR.
  /// Returns a map of currency codes to their values (calculated to base IDR).
  Future<Map<String, double>> fetchExchangeRates() async {
    try {
      // The API base is USD by default in the free version usually, 
      // but we can query with IDR if the API supports it.
      final response = await http.get(Uri.parse('$_baseUrl/IDR')).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] == 'success') {
          final rates = data['rates'] as Map<String, dynamic>;
          // We want rates relative to 1 [Target Currency] = [X] IDR
          // This API returns 1 IDR = [X] [Target Currency]
          // So we need to calculate 1 [Target] = 1/X IDR
          Map<String, double> convertedRates = {};
          rates.forEach((key, value) {
            if (value != 0) {
              convertedRates[key] = 1.0 / (value as num).toDouble();
            }
          });
          return convertedRates;
        }
      }
      throw Exception('Failed to load exchange rates');
    } catch (e) {
      print('Error fetching rates: $e');
      // Fallback mockup rates if API fails or offline
      return {
        'USD': 15700.0,
        'EUR': 17000.0,
        'SGD': 11600.0,
        'JPY': 105.0,
        'MYR': 3300.0,
        'IDR': 1.0,
      };
    }
  }

  /// Converts an amount from [fromCurrency] to IDR based on provided [rates].
  double convertToIdr(double amount, String fromCurrency, Map<String, double> rates) {
    if (fromCurrency == 'IDR') return amount;
    final rate = rates[fromCurrency] ?? 0;
    return amount * rate;
  }
}
