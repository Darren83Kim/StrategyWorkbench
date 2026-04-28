import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:strategy_workbench/core/constants/api_keys.dart';
import 'package:strategy_workbench/features/strategy/data/repositories/hybrid_stock_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final repo = HybridStockRepository();
  final status = repo.getStatus();

  debugPrint('status=$status');

  try {
    final usStocks = await repo.getUsStocks();
    debugPrint(
      'usCount=${usStocks.length} sample=${usStocks.take(3).map((stock) => stock.ticker).join(",")}',
    );
  } catch (error) {
    debugPrint('usError=$error');
  }

  try {
    final krStocks = await repo.getKoreanStocks();
    debugPrint(
      'krCount=${krStocks.length} sample=${krStocks.take(3).map((stock) => stock.ticker).join(",")}',
    );
  } catch (error) {
    debugPrint('krError=$error');
  }

  try {
    final allStocks = await repo.getAllStocks();
    debugPrint(
      'allCount=${allStocks.length} sample=${allStocks.take(5).map((stock) => stock.ticker).join(",")}',
    );
  } catch (error) {
    debugPrint('allError=$error');
  }

  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
    ),
  );

  try {
    final quoteResponse = await dio.get(
      '${ApiKeys.finnhubBaseUrl}/quote',
      queryParameters: {
        'symbol': 'AAPL',
        'token': ApiKeys.finnhubApiKey,
      },
    );
    debugPrint(
      'rawFinnhubQuoteStatus=${quoteResponse.statusCode} price=${quoteResponse.data['c']}',
    );
  } catch (error) {
    debugPrint('rawFinnhubQuoteError=$error');
  }

  try {
    final yahooResponse = await dio.get(
      '${ApiKeys.yahooBaseUrl}/v10/finance/quoteSummary/AAPL',
      queryParameters: {
        'modules': 'price,summaryDetail,defaultKeyStatistics',
      },
    );
    final result = yahooResponse.data['quoteSummary']?['result'] as List?;
    debugPrint(
      'rawYahooStatus=${yahooResponse.statusCode} resultCount=${result?.length ?? 0}',
    );
  } catch (error) {
    debugPrint('rawYahooError=$error');
  }

  try {
    final fmpResponse = await dio.get(
      'https://financialmodelingprep.com/stable/profile',
      queryParameters: {
        'symbol': 'AAPL',
        'apikey': ApiKeys.fmpApiKey,
      },
    );
    final payload = fmpResponse.data as List<dynamic>;
    debugPrint(
      'rawFmpProfileStatus=${fmpResponse.statusCode} resultCount=${payload.length}',
    );
  } catch (error) {
    debugPrint('rawFmpError=$error');
  }
}
