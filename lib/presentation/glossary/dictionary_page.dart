import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class DictionaryPage extends StatefulWidget {
  final int dictionaryId;

  const DictionaryPage({Key? key, required this.dictionaryId}) : super(key: key);

  @override
  _DictionaryPageState createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  List<String> languages = []; // Языки в словаре
  List<List<String>> words = []; // Слова в словаре

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final dbPath = await getDatabasesPath();
    final db = await openDatabase('$dbPath/dictionary.db');

    // Извлекаем языки для данного словаря
    final languageRows = await db.rawQuery('''
    SELECT l.name
    FROM languages l
    INNER JOIN dictionary_languages dl ON l.id = dl.language_id
    WHERE dl.dictionary_id = ?
  ''', [widget.dictionaryId]);

    languages = languageRows.map((row) => row['name'] as String).toList();

    // Извлекаем слова и их переводы
    final wordRows = await db.rawQuery('''
    SELECT t.word_id, t.translated_word, l.name AS language_name
    FROM translations t
    INNER JOIN languages l ON t.language_id = l.id
    INNER JOIN words w ON t.word_id = w.id
    WHERE w.dictionary_id = ?
  ''', [widget.dictionaryId]);

    words = _groupWordsByLanguages(wordRows);

    setState(() {});
  }

  // Группировка слов по языкам
  List<List<String>> _groupWordsByLanguages(List<Map<String, Object?>> wordRows) {
    final Map<int, Map<String, String>> groupedWords = {};

    for (var row in wordRows) {
      final wordId = row['word_id'] as int; // ID слова
      final translatedWord = row['translated_word'] as String;
      final languageName = row['language_name'] as String;

      if (!groupedWords.containsKey(wordId)) {
        groupedWords[wordId] = {};
      }

      groupedWords[wordId]![languageName] = translatedWord;
    }

    // Добавляем ID слова как первый элемент списка
    return groupedWords.entries.map((entry) {
      final wordTranslations = entry.value;
      final wordList = List.generate(languages.length, (index) => '');
      for (int i = 0; i < languages.length; i++) {
        wordList[i] = wordTranslations[languages[i]] ?? '';
      }
      return [entry.key.toString(), ...wordList]; // ID слова + переводы
    }).toList();
  }

  Future<void> _showAddWordForm() async {
    // Запрос для получения id и названий языков в текущем словаре
    final dbPath = await getDatabasesPath();
    final db = await openDatabase('$dbPath/dictionary.db');
    final languageRows = await db.rawQuery('''
    SELECT l.id, l.name
    FROM languages l
    INNER JOIN dictionary_languages dl ON l.id = dl.language_id
    WHERE dl.dictionary_id = ?
  ''', [widget.dictionaryId]);

    // Формируем Map<id, TextEditingController> для всех языков словаря
    final translationControllers = {
      for (var row in languageRows) row['id'] as int: TextEditingController(),
    };

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFFFDFBE8),
          title: const Text('Добавить слово'),
          content: Scrollbar(
            thumbVisibility: true, // Для видимости скроллбара
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Поля для перевода на языки из словаря
                  ...translationControllers.entries.map((entry) {
                    final languageId = entry.key; // ID языка
                    final languageName = languageRows
                        .firstWhere((row) => row['id'] == languageId)['name'] as String;

                    return TextField(
                      controller: entry.value,
                      decoration: InputDecoration(
                        labelText: 'Перевод на $languageName',
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Закрыть форму без сохранения
              },
              child: Icon(
                Icons.close,
                color: Color(0xFF438589),
                size: 30,
              ),
            ),
            TextButton(
              onPressed: () async {
                // Собираем переводы
                final translations = {
                  for (var entry in translationControllers.entries)
                    entry.key: entry.value.text.trim()
                };

                // Проверяем наличие хотя бы одного перевода
                if (translations.values.any((t) => t.isNotEmpty)) {
                  await _saveWord(translations);
                  Navigator.of(context).pop(); // Закрыть форму
                  _loadData(); // Обновить данные на странице
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Добавьте хотя бы один перевод')),
                  );
                }
              },
              child: Icon(
                Icons.done,
                color: Color(0xFF438589),
                size: 30,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditWordForm(int wordId) async {
    final dbPath = await getDatabasesPath();
    final db = await openDatabase('$dbPath/dictionary.db');

    // Получаем текущие переводы слова
    final translationRows = await db.rawQuery('''
    SELECT t.language_id, t.translated_word, l.name AS language_name
    FROM translations t
    INNER JOIN languages l ON t.language_id = l.id
    WHERE t.word_id = ?
  ''', [wordId]);

    // Создаем контроллеры для текстовых полей
    final translationControllers = {
      for (var row in translationRows)
        row['language_id'] as int: TextEditingController(text: row['translated_word'] as String),
    };

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFDFBE8),
          title: const Text('Редактировать слово'),
          content: SingleChildScrollView(
            child: Column(
              children: translationControllers.entries.map((entry) {
                final languageId = entry.key;
                final languageName = translationRows
                    .firstWhere((row) => row['language_id'] == languageId)['language_name'] as String;

                return TextField(
                  controller: entry.value,
                  decoration: InputDecoration(labelText: 'Перевод на $languageName'),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Icon(
                Icons.close,
                color: Color(0xFF438589),
                size: 30,
              ),
            ),
            TextButton(
              onPressed: () async {
                // Обновляем переводы
                for (var entry in translationControllers.entries) {
                  final languageId = entry.key;
                  final translatedWord = entry.value.text.trim();

                  await db.update(
                    'translations',
                    {'translated_word': translatedWord},
                    where: 'word_id = ? AND language_id = ?',
                    whereArgs: [wordId, languageId],
                  );
                }

                Navigator.of(context).pop();
                _loadData(); // Обновляем данные
              },
              child: const Icon(
                Icons.done,
                color: Color(0xFF438589),
                size: 30,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveWord(Map<int, String> translations) async {
    final dbPath = await getDatabasesPath();
    final db = await openDatabase('$dbPath/dictionary.db');

    // Вставляем слово в таблицу `words` без указания оригинального слова
    final wordId = await db.insert('words', {
      'dictionary_id': widget.dictionaryId,
    });

    // Вставляем переводы
    for (var entry in translations.entries) {
      final languageId = entry.key; // ID языка
      final translatedWord = entry.value; // Перевод на языке

      if (translatedWord.isNotEmpty) {
        await db.insert('translations', {
          'word_id': wordId,
          'language_id': languageId,
          'translated_word': translatedWord,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBE8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF438589),
        title: const Text('Словарь'),
      ),
      body: Column(
        children: [
          // Поле поиска
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Введите слово для поиска',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                // Логика поиска
              },
            ),
          ),
          // Таблица
          Expanded(
            child: Scrollbar(
              thumbVisibility: true, // Показывает скроллбар при прокрутке
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: languages.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : DataTable(
                      columns: languages.map((lang) => DataColumn(label: Text(lang))).toList(),
                      rows: words.map(
                            (wordRow) {
                          final wordId = int.parse(wordRow[0]); // ID слова
                          return DataRow(
                            cells: wordRow.sublist(1).map(
                                  (word) {
                                return DataCell(
                                  Text(word),
                                  onTap: () => _showEditWordForm(wordId),
                                );
                              },
                            ).toList(),
                          );
                        },
                      ).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Кнопка редактирования
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF438589),
              onPressed: () async {
                await _showAddWordForm();
                await _loadData(); // Перезагружаем данные
              },
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );

  }
}
