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

    // Извлекаем слова и их переводы с учетом языков
    final wordRows = await db.rawQuery('''
    SELECT w.original_word, t.translated_word, l.name AS language_name
    FROM words w
    INNER JOIN translations t ON w.id = t.word_id
    INNER JOIN languages l ON t.language_id = l.id
    WHERE w.dictionary_id = ?
  ''', [widget.dictionaryId]);

    words = _groupWordsByLanguages(wordRows);

    setState(() {});
  }

  // Группировка слов по языкам
  List<List<String>> _groupWordsByLanguages(List<Map<String, Object?>> wordRows) {
    final Map<String, Map<String, String>> groupedWords = {};

    for (var row in wordRows) {
      final originalWord = row['original_word'] as String;
      final translatedWord = row['translated_word'] as String;
      final languageName = row['language_name'] as String;

      // Если слово еще не добавлено в группу, создаем его
      if (!groupedWords.containsKey(originalWord)) {
        groupedWords[originalWord] = {};
      }

      // Привязываем перевод к языку
      groupedWords[originalWord]![languageName] = translatedWord;
    }

    // Преобразуем в список для DataTable
    return groupedWords.entries.map((entry) {
      final wordList = List.generate(languages.length, (index) => '');
      wordList[0] = entry.key; // Оригинальное слово

      for (int i = 0; i < languages.length; i++) {
        wordList[i] = entry.value[languages[i]] ?? ''; // Перевод или пустая строка
      }
      return wordList;
    }).toList();
  }

  Future<void> _showAddWordForm() async {
    final originalWordController = TextEditingController();

    // Запрос для получения id и названий языков в текущем словаре
    final dbPath = await getDatabasesPath();
    final db = await openDatabase('$dbPath/dictionary.db');
    final languageRows = await db.rawQuery('''
    SELECT l.id, l.name
    FROM languages l
    INNER JOIN dictionary_languages dl ON l.id = dl.language_id
    WHERE dl.dictionary_id = ?
  ''', [widget.dictionaryId]);

    // Формируем Map<id, TextEditingController> только для языков из словаря
    final translationControllers = {
      for (var row in languageRows) row['id'] as int: TextEditingController(),
    };

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Добавить слово'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                // Поле для ввода оригинального слова
                TextField(
                  controller: originalWordController,
                  decoration: const InputDecoration(labelText: 'Оригинальное слово'),
                ),
                const SizedBox(height: 16),
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
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Закрыть форму без сохранения
              },
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                // Сохраняем данные
                final originalWord = originalWordController.text;
                final translations = {
                  for (var entry in translationControllers.entries)
                    entry.key: entry.value.text
                };

                if (originalWord.isNotEmpty && translations.values.any((t) => t.isNotEmpty)) {
                  await _saveWord(originalWord, translations);
                  Navigator.of(context).pop(); // Закрыть форму
                  _loadData(); // Обновить данные на странице
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveWord(String originalWord, Map<int, String> translations) async {
    final dbPath = await getDatabasesPath();
    final db = await openDatabase('$dbPath/dictionary.db');

    // Вставляем оригинальное слово
    final wordId = await db.insert('words', {
      'original_word': originalWord,
      'language_id': 1, // ID языка оригинального слова (например, 1 — English)
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
      backgroundColor: Color(0xFFFDFBE8),
      appBar: AppBar(
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: languages.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : DataTable(
                  columns: languages
                      .map((lang) => DataColumn(label: Text(lang)))
                      .toList(),
                  rows: words
                      .map(
                        (wordRow) => DataRow(
                      cells: wordRow
                          .map((word) => DataCell(Text(word)))
                          .toList(),
                    ),
                  )
                      .toList(),
                ),
              ),
            ),
          ),
          // Кнопка редактирования
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FloatingActionButton(
              backgroundColor: Color(0xFF438589),
              onPressed: () async {
                await _showAddWordForm();
                await _loadData(); // Перезагружаем данные
              },
              child: Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
