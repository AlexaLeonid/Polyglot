import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('dictionary.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE languages (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL
    );
    ''');

    await db.execute('''
    CREATE TABLE dictionaries (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      count_of_languages INTEGER NOT NULL,
      word_of_chain_id INTEGER,
      FOREIGN KEY (word_of_chain_id) REFERENCES chain_of_words (id)
    );
    ''');

    await db.execute('''
    CREATE TABLE words (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      language_id INTEGER NOT NULL,
      FOREIGN KEY (language_id) REFERENCES languages (id)
    );
    ''');

    await db.execute('''
    CREATE TABLE chain_of_words (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      word_id INTEGER NOT NULL,
      FOREIGN KEY (word_id) REFERENCES words (id)
    );
    ''');
  }

  Future<void> insertLanguage(String name) async {
    final db = await instance.database;

    await db.insert('languages', {'name': name});
  }

  Future<void> insertDictionary(String name, int? chainId, int? countOfLanguages) async {
    final db = await instance.database;

    await db.insert('dictionaries', {
      'name': name,
      'word_of_chain_id': chainId,
      'count_of_languages': countOfLanguages,
    });
  }

  Future<void> insertWord(String name, int languageId) async {
    final db = await instance.database;

    await db.insert('words', {
      'name': name,
      'language_id': languageId,
    });
  }

  Future<void> insertChainOfWord(int chainId, int wordId) async {
    final db = await instance.database;

    await db.insert('chain_of_words', {
      'id': chainId, // ID цепочки
      'word_id': wordId, // ID слова
    });
  }

  Future<List<Map<String, dynamic>>> fetchWordsInDictionary(int dictionaryId) async {
    final db = await instance.database;

    final result = await db.rawQuery('''
    SELECT words.name AS word, languages.name AS language
    FROM words
    INNER JOIN languages ON words.language_id = languages.id
    INNER JOIN chain_of_words ON words.id = chain_of_words.word_id
    INNER JOIN dictionaries ON dictionaries.word_of_chain_id = chain_of_words.id
    WHERE dictionaries.id = ?
    ''', [dictionaryId]);

    return result;
  }
}
