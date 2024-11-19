import 'dart:ffi';

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

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
  CREATE TABLE languages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    code TEXT NOT NULL
  );
  ''');

    await db.execute('''
  CREATE TABLE dictionaries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT,
    count_of_languages INTEGER NOT NULL DEFAULT 0
  );
  ''');

    await db.execute('''
  CREATE TABLE words (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    original_word TEXT NOT NULL,
    language_id INTEGER NOT NULL,
    dictionary_id INTEGER NOT NULL,
    FOREIGN KEY (language_id) REFERENCES languages (id),
    FOREIGN KEY (dictionary_id) REFERENCES dictionaries (id)
  );
  ''');

    await db.execute('''
  CREATE TABLE translations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    word_id INTEGER NOT NULL,
    language_id INTEGER NOT NULL,
    translated_word TEXT NOT NULL,
    FOREIGN KEY (word_id) REFERENCES words (id),
    FOREIGN KEY (language_id) REFERENCES languages (id)
  );
  ''');

    // Новая таблица для связи словарей и языков
    await db.execute('''
  CREATE TABLE dictionary_languages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    dictionary_id INTEGER NOT NULL,
    language_id INTEGER NOT NULL,
    FOREIGN KEY (dictionary_id) REFERENCES dictionaries (id),
    FOREIGN KEY (language_id) REFERENCES languages (id)
  );
  ''');

    // Наполняем таблицу languages
    await _populateLanguages(db);
  }

  Future<void> _populateLanguages(Database db) async {
    final languages = [
      {'name': 'English', 'code': 'en'},
      {'name': 'Russian', 'code': 'ru'},
      {'name': 'Spanish', 'code': 'es'},
      {'name': 'French', 'code': 'fr'},
      {'name': 'German', 'code': 'de'},
      {'name': 'Chinese', 'code': 'zh'},
      {'name': 'Japanese', 'code': 'ja'},
      {'name': 'Italian', 'code': 'it'},
      {'name': 'Portuguese', 'code': 'pt'},
      {'name': 'Korean', 'code': 'ko'},
    ];

    for (var language in languages) {
      await db.insert('languages', language);
    }
  }

  /// Insert operations
  Future<int> insertLanguage(String name, String code) async {
    final db = await database;
    return await db.insert('languages', {'name': name, 'code': code});
  }

  Future<int> insertDictionary(String name, String description) async {
    final db = await database;
    return await db.insert('dictionaries', {
      'name': name,
      'description': description,
    });
  }

  Future<void> insertLanguageForDictionary(int dictionaryId, int languageId) async {
    final db = await database;
    await db.insert('dictionary_languages', {
      'dictionary_id': dictionaryId,
      'language_id': languageId,
    });
  }

  Future<int> insertWord(String originalWord, int languageId, int dictionaryId) async {
    final db = await database;
    return await db.insert('words', {
      'original_word': originalWord,
      'language_id': languageId,
      'dictionary_id': dictionaryId,
    });
  }

  Future<int> insertTranslation(int wordId, int languageId, String translatedWord) async {
    final db = await database;
    return await db.insert('translations', {
      'word_id': wordId,
      'language_id': languageId,
      'translated_word': translatedWord,
    });
  }

  Future<List<Map<String, dynamic>>> fetchDictionariesWithLanguages() async {
    final db = await database;

    // Получаем список словарей с их языками
    final result = await db.rawQuery('''
    SELECT d.id, d.name, d.description, 
           GROUP_CONCAT(l.code, '-') AS language_codes
    FROM dictionaries d
    LEFT JOIN dictionary_languages dl ON d.id = dl.dictionary_id
    LEFT JOIN languages l ON dl.language_id = l.id
    GROUP BY d.id, d.name, d.description
  ''');
    return result;
  }

  /// Fetch operations
  Future<List<Map<String, dynamic>>> fetchLanguages() async {
    final db = await database;
    return await db.query('languages');
  }

  Future<List<Map<String, dynamic>>> fetchDictionaries() async {
    final db = await database;
    return await db.query('dictionaries');
  }

  Future<List<Map<String, dynamic>>> fetchWordsInDictionary(int dictionaryId) async {
    final db = await database;

    return await db.rawQuery('''
    SELECT w.original_word, l.name AS language_name
    FROM words w
    INNER JOIN languages l ON w.language_id = l.id
    WHERE w.dictionary_id = ?
    ''', [dictionaryId]);
  }

  Future<List<Map<String, dynamic>>> fetchTranslations(int wordId) async {
    final db = await database;

    return await db.rawQuery('''
    SELECT t.translated_word, l.name AS language_name
    FROM translations t
    INNER JOIN languages l ON t.language_id = l.id
    WHERE t.word_id = ?
    ''', [wordId]);
  }

  /// Delete operations
  Future<int> deleteDictionary(int dictionaryId) async {
    final db = await database;
    return await db.delete(
      'dictionaries',
      where: 'id = ?',
      whereArgs: [dictionaryId],
    );
  }

  Future<int> deleteWord(int wordId) async {
    final db = await database;
    return await db.delete(
      'words',
      where: 'id = ?',
      whereArgs: [wordId],
    );
  }

  Future<int> deleteTranslation(int translationId) async {
    final db = await database;
    return await db.delete(
      'translations',
      where: 'id = ?',
      whereArgs: [translationId],
    );
  }

  /// Update operations
  Future<int> updateDictionary(int dictionaryId, String name, String? description) async {
    final db = await database;
    return await db.update(
      'dictionaries',
      {
        'name': name,
        'description': description,
      },
      where: 'id = ?',
      whereArgs: [dictionaryId],
    );
  }

  Future<int> updateWord(int wordId, String originalWord) async {
    final db = await database;
    return await db.update(
      'words',
      {'original_word': originalWord},
      where: 'id = ?',
      whereArgs: [wordId],
    );
  }
}
