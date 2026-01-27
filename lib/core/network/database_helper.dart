import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../features/portfolio/domain/entities/transaction.dart' as model;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('transactions.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE transactions ( 
  id $idType, 
  ticker $textType,
  type $textType,
  price $realType,
  quantity $integerType,
  dateTime $textType
  )
''');
  }

  Future<model.Transaction> create(model.Transaction transaction) async {
    final db = await instance.database;
    final id = await db.insert('transactions', {
      'ticker': transaction.ticker,
      'type': transaction.type.toString(),
      'price': transaction.price,
      'quantity': transaction.quantity,
      'dateTime': transaction.dateTime.toIso8601String(),
    });
    return model.Transaction(
      id: id,
      ticker: transaction.ticker,
      type: transaction.type,
      price: transaction.price,
      quantity: transaction.quantity,
      dateTime: transaction.dateTime,
    );
  }

  Future<List<model.Transaction>> readAllTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions');
    return result.map((json) => model.Transaction(
      id: json['id'] as int,
      ticker: json['ticker'] as String,
      type: (json['type'] as String) == 'TransactionType.BUY' ? model.TransactionType.BUY : model.TransactionType.SELL,
      price: json['price'] as double,
      quantity: json['quantity'] as int,
      dateTime: DateTime.parse(json['dateTime'] as String),
    )).toList();
  }
  
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
