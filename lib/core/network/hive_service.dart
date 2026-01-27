import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/strategy/domain/entities/stock.dart';

class HiveService {
  Future<void> init() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);

    // Registering Adapters
    // Make sure to generate the adapter for the Stock class
    Hive.registerAdapter(StockAdapter()); 

    await Hive.openBox('stock_cache');
    await Hive.openBox('settings');
  }

  Box get stockCache => Hive.box('stock_cache');
  Box get settings => Hive.box('settings');
}
