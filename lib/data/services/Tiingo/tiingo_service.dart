import 'package:dio/dio.dart';
import '../../database/database.dart';

class TiingoService {
  final Dio _dio;
  final String _baseUrl = 'https://api.tiingo.com/tiingo';
  final String _apiToken;

  TiingoService({required String apiToken, Dio? dio})
      : _apiToken = apiToken,
        _dio = dio ?? Dio();

  Future<List<StockPricesCompanion>> fetchDailyPrices(
    String ticker, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final effectiveStartDate = startDate ?? DateTime(2023, 1, 1);
      final queryParams = {
        'token': _apiToken,
        'startDate': '${effectiveStartDate.year}-${effectiveStartDate.month.toString().padLeft(2, '0')}-${effectiveStartDate.day.toString().padLeft(2, '0')}',
      };
      
      if (endDate != null) {
        queryParams['endDate'] = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
      }
      
      final response = await _dio.get(
        '$_baseUrl/daily/$ticker/prices',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) {
          return StockPricesCompanion.insert(
            ticker: ticker,
            date: DateTime.parse(json['date']),
            open: (json['open'] as num).toDouble(),
            close: (json['adjClose'] as num).toDouble(), // Use adjClose for backtesting
            high: (json['high'] as num).toDouble(),
            low: (json['low'] as num).toDouble(),
            volume: (json['volume'] as num).toInt(),
          );
        }).toList();
      } else {
        throw Exception('Failed to fetch prices: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching Tiingo prices: $e');
    }
  }
}
