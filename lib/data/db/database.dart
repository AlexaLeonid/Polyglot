import 'dart:convert';

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
    dictionary_id INTEGER NOT NULL,
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

  // Функция для поиска языка по коду
  Future<Map<String, dynamic>?> getLanguageByCode(String code) async {
    final db = await _database;
    final result = await db!.query(
      'languages',
      where: 'code = ?',
      whereArgs: [code],
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
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

  Future<int> insertWord(int dictionaryId) async {
    final db = await database;
    return await db.insert('words', {
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

  Future<List<Map<String, dynamic>>> fetchDictionaryLanguages(int dictionaryId) async {
    final db = await database;

    // Получаем языки, связанные с данным словарём
    final result = await db.rawQuery('''
    SELECT l.id, l.name, l.code
    FROM languages l
    INNER JOIN dictionary_languages dl ON dl.language_id = l.id
    WHERE dl.dictionary_id = ?
  ''', [dictionaryId]);

    return result;
  }

  Future<Map<String, dynamic>> fetchDictionaryById(int dictionaryId) async {
    final db = await database;
    final result = await db.query(
      'dictionaries',
      where: 'id = ?',
      whereArgs: [dictionaryId],
    );
    return result.isNotEmpty ? result.first : {};
  }

  Future<List<Map<String, dynamic>>> fetchWordsInDictionary(int dictionaryId) async {
    final db = await database;
    return await db.query(
      'words',
      where: 'dictionary_id = ?',
      whereArgs: [dictionaryId],
    );
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

  Future<void> clearLanguagesForDictionary(int dictionaryId) async {
    final db = await database;

    // Удаление всех записей для указанного словаря
    await db.delete(
      'dictionary_languages',
      where: 'dictionary_id = ?',
      whereArgs: [dictionaryId],
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

  Future<String> exportSpecificDictionariesToJson(List<int> dictionaryIds) async {
    final db = await database;

    // Получаем словари и их языки
    final dictionaries = await db.rawQuery('''
    SELECT d.id, d.name, d.description, 
           GROUP_CONCAT(l.name, ',') AS language_names,
           GROUP_CONCAT(l.code, ',') AS language_codes
    FROM dictionaries d
    LEFT JOIN dictionary_languages dl ON d.id = dl.dictionary_id
    LEFT JOIN languages l ON dl.language_id = l.id
    WHERE d.id IN (${dictionaryIds.join(',')})
    GROUP BY d.id, d.name, d.description
  ''');

    // Собираем данные о словах и переводах для каждого словаря
    List<Map<String, dynamic>> exportData = [];
    for (final dictionary in dictionaries) {
      final words = await db.rawQuery('''
      SELECT w.id AS word_id
      FROM words w
      WHERE w.dictionary_id = ?
    ''', [dictionary['id']]);

      // Для каждого слова получаем переводы
      List<Map<String, dynamic>> wordsData = [];
      for (final word in words) {
        final translations = await db.rawQuery('''
        SELECT t.translated_word, l.code AS language_code
        FROM translations t
        INNER JOIN languages l ON t.language_id = l.id
        WHERE t.word_id = ?
      ''', [word['word_id']]);

        wordsData.add({
          "translations": translations,
        });
      }

      // Формируем объект словаря
      exportData.add({
        "dictionary": {
          "name": dictionary['name'],
          "description": dictionary['description'],
          "languages": _parseLanguages(
              dictionary['language_names'] as String?,
              dictionary['language_codes'] as String?
          ),
          "words": wordsData,
        }
      });
    }

    return jsonEncode(exportData);
  }

  List<Map<String, String>> _parseLanguages(String? names, String? codes) {
    if (names == null || codes == null) return [];
    final nameList = names.split(',');
    final codeList = codes.split(',');
    return List.generate(nameList.length, (i) => {
      "name": nameList[i],
      "code": codeList[i],
    });
  }

  Future<Map<int, Map<String, Map<String, List<String>>>>> fetchDictionaryOfDictionariesWithLanguages(
      List<int> dictionaryIds) async {
    final db = await database;

    // Проверяем, есть ли переданные ID
    if (dictionaryIds.isEmpty) {
      return {}; // Возвращаем пустой словарь, если список ID пуст
    }

    // Формируем строку для SQL-запроса с помощью плейсхолдеров
    final placeholders = List.filled(dictionaryIds.length, '?').join(', ');
    final dictionaries = await db.rawQuery('''
    SELECT * 
    FROM dictionaries 
    WHERE id IN ($placeholders)
  ''', dictionaryIds);

    // Инициализируем результирующую структуру
    Map<int, Map<String, Map<String, List<String>>>> dictionaryWithLanguages = {};

    for (var dictionary in dictionaries) {
      int dictionaryId = int.parse(dictionary['id'].toString());

      // Получаем все слова для текущего словаря
      final words = await db.query(
        'words',
        where: 'dictionary_id = ?',
        whereArgs: [dictionaryId],
      );

      // Инициализируем Map для слов текущего словаря
      Map<String, Map<String, List<String>>> wordsMap = {};

      for (var word in words) {
        int wordId = int.parse(word['id'].toString());

        // Получаем переводы для текущего слова с языком
        final translations = await db.rawQuery('''
        SELECT t.translated_word, l.name AS language_name 
        FROM translations t
        INNER JOIN languages l ON t.language_id = l.id
        WHERE t.word_id = ?
      ''', [wordId]);

        // Группируем переводы по языкам
        Map<String, List<String>> translationsByLanguage = {};

        for (var translation in translations) {
          String languageName = translation['language_name'] as String;
          String translatedWord = translation['translated_word'] as String;

          if (!translationsByLanguage.containsKey(languageName)) {
            translationsByLanguage[languageName] = [];
          }
          translationsByLanguage[languageName]!.add(translatedWord);
        }

        // Добавляем слово и его переводы (группированные по языкам) в Map текущего словаря
        wordsMap[word['id'].toString()] = translationsByLanguage;
      }

      // Добавляем текущий словарь в итоговую структуру
      dictionaryWithLanguages[dictionaryId] = wordsMap;
    }

    return dictionaryWithLanguages;
  }

}

extension on Object? {
  split(String s) {}
}
