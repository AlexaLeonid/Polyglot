import 'side_menu.dart';
import 'package:flutter/material.dart';
import '../data/db/database.dart';
import 'glossary/dictionary_page.dart';
import 'glossary/glossary_addition_page.dart';
import 'dart:convert'; // Для работы с JSON
import 'dart:io'; // Для работы с файлами
import 'package:path_provider/path_provider.dart'; // Для получения директории
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'bottom_menu.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _dictionariesFuture;

  @override
  void initState() {
    super.initState();
    _loadDictionaries();
  }
  void _loadDictionaries() {
    setState(() {
      _dictionariesFuture = DatabaseHelper.instance.fetchDictionariesWithLanguages();
    });
  }

  Future<File?> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      return File(result.files.single.path!);
    } else {
      return null;
    }
  }

  Future<int?> _getLanguageIdByCode(String code) async {
    final dbHelper = await DatabaseHelper.instance;
    final language = await dbHelper.getLanguageByCode(code); // Запрос в БД по коду языка
    return language != null ? language['id'] : null;
  }

  Future<void> _exportDictionary(int dictionaryId) async {
    final dbHelper = await DatabaseHelper.instance;

    try {
      // Преобразуем в JSON
      final jsonExport = await dbHelper.exportSpecificDictionariesToJson([dictionaryId]); // Используем await

      // Сохраняем файл
      final dictionary = await dbHelper.fetchDictionaryById(dictionaryId);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${dictionary["name"]}.json');
      await file.writeAsString(jsonExport);

      // Используем Share для отправки файла
      await Share.shareXFiles([XFile(file.path)], text: 'Вот экспортированный словарь: ${dictionary["name"]}');

      // Информируем пользователя
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Экспорт завершен и файл отправлен!')),
      );
    } catch (e) {
      // Обработка ошибки
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при экспорте: $e')),
      );
    }
  }

  Future<void> _importDictionary() async {
    final dbHelper = await DatabaseHelper.instance;

    // Открываем файл импорта
    final file = await _pickFile();
    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось выбрать файл')),
      );
      return;
    }

    // Чтение содержимого файла
    final fileContent = await file.readAsString();
    final List<dynamic> importData = jsonDecode(fileContent);

    for (var dictionaryData in importData) {
      final dictionary = dictionaryData['dictionary'];

      // Вставляем словарь в базу
      final dictionaryId = await dbHelper.insertDictionary(
        dictionary['name'],
        dictionary['description'],
      );

      // Обработка языков
      final languages = dictionary['languages'] ?? [];
      for (var language in languages) {
        // Проверяем, существует ли язык
        final languageId = await _getLanguageIdByCode(language['code']);
        int finalLanguageId;

        if (languageId != null) {
          // Язык существует, используем его ID
          finalLanguageId = languageId;
        } else {
          // Добавляем новый язык
          finalLanguageId = await dbHelper.insertLanguage(language['name'], language['code']);
        }

        // Добавляем язык в словарь
        await dbHelper.insertLanguageForDictionary(dictionaryId, finalLanguageId);
      }

      // Обработка слов и их переводов
      final words = dictionary['words'] ?? [];
      for (var wordData in words) {
        final wordId = await dbHelper.insertWord(dictionaryId);
        for (var translation in wordData['translations']) {
          // Получаем ID языка по коду
          final languageId = await _getLanguageIdByCode(translation['language_code']);
          if (languageId != null) {
            await dbHelper.insertTranslation(
              wordId,
              languageId,
              translation['translated_word'],
            );
          } else {
            throw Exception("Язык с кодом ${translation['language_code']} не найден!");
          }
        }
      }
    }

    // Информируем пользователя о завершении импорта
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Импорт завершен!')),
    );

    // Перезагружаем данные
    _loadDictionaries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDFBE8), // Светлый бежевый цвет
      appBar: AppBar(
        backgroundColor: Color(0xFF438589), // Бирюзовый цвет
        title: SizedBox.shrink(), // Убираем текст в AppBar
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
            Icons.person_outline, // Иконка пользователя
            color: Color(0xFFFDFBE8),
            size: 28,
          ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),

      ),
      drawer: MyDrawer(),
      body: Column(
        children: [
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(

            future: _dictionariesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text("Ошибка: ${snapshot.error}"));
              } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    "Добавьте первый словарь!",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                );
              } else {
                final dictionaries = snapshot.data!;
                return ListView.builder(
                  padding: EdgeInsets.all(16.0),
                  itemCount: dictionaries.length,
                  itemBuilder: (context, index) {
                    final dictionary = dictionaries[index];
                    return Card(
                      color: Color(0xFFFDFBE8),
                      margin: EdgeInsets.only(bottom: 16.0),
                      child: ListTile(
                        title: Text(dictionary['name'] ?? 'Без названия'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dictionary['description'] ?? 'Нет описания'),
                            if (dictionary['language_codes'] != null)
                              Text(
                                dictionary['language_codes'], // Цепочка кодов языков
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              _deleteDictionary(dictionary['id']);
                            } else if (value == 'export') {
                              _exportDictionary(dictionary['id']);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Удалить'),
                            ),
                            PopupMenuItem(
                              value: 'export',
                              child: Text('Экспортировать'),
                            ),
                          ],
                        ),
                          onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DictionaryPage(dictionaryId: dictionary['id']),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
        ]
    ),

      bottomNavigationBar: CustomBottomAppBar(
        context: context,
        importDictionary: _importDictionary, // Передаем функцию
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddDictionaryPage()),
          );
          _loadDictionaries(); // Перезагружаем список после добавления
        },
        backgroundColor: Color(0xFF438589),
        child: Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );

  }
  Future<void> _deleteDictionary(int dictionaryId) async {
    final dbHelper = await DatabaseHelper.instance;
    await dbHelper.deleteDictionary(dictionaryId);
    _loadDictionaries(); // Обновляем список после удаления
  }
}