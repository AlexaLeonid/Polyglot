import 'dart:convert';
import 'package:Polyglot/presentation/DickHub/user_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../data/db/database.dart';
import '../bottom_menu.dart';

class Dictionary {
  final String name;
  final int id;
  final String description;
  final String langChain;
  final double rating;
  final String owner;

  Dictionary({
    required this.name,
    required this.id,
    required this.description,
    required this.langChain,
    required this.rating,
    required this.owner,
  });

  factory Dictionary.fromJson(Map<String, dynamic> json) {
    return Dictionary(
      name: json['name'],
      id: json['id'],
      description: json['description'],
      langChain: json['lang_chain'],
      rating: (json['rating'] as num).toDouble(),
      owner: json['owner']
    );
  }
}

class DictionaryHubPage extends StatefulWidget {
  @override
  _DictionaryHubPageState createState() => _DictionaryHubPageState();
}

class _DictionaryHubPageState extends State<DictionaryHubPage> {
  late Future<List<Dictionary>> _dictionaries;

  Future<List<Dictionary>> fetchDictionaries() async {
    final response = await http.get(Uri.parse(
        'https://sublimely-many-mule.cloudpub.ru:443/dictionaries/'));

    if (response.statusCode == 200) {
      // Декодируем байты в строку с правильной кодировкой
      final decodedBody = utf8.decode(response.bodyBytes);
      List<dynamic> data = json.decode(decodedBody);
      return data.map((json) => Dictionary.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load dictionaries');
    }
  }

  Future<void> downloadAndImportDictionary(int id) async {
    try {
      final response = await http.get(Uri.parse(
          'https://sublimely-many-mule.cloudpub.ru:443/dictionaries/$id'));

      if (response.statusCode == 200) {
        // Декодируем байты в строку с правильной кодировкой
        final decodedBody = utf8.decode(response.bodyBytes);
        final dictionaryData = json.decode(decodedBody);

        // Сохранение данных в файл
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/dictionary_$id.json';
        final file = File(filePath);
        await file.writeAsString(jsonEncode(dictionaryData));

        // Импорт словаря
        await _importDictionary(file);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Импорт словаря завершен!')),
        );
      } else {
        throw Exception('Failed to fetch dictionary data');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при скачивании: $e')),
      );
    }
  }

  Future<void> _importDictionary(File file) async {
    final dbHelper = await DatabaseHelper.instance;

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
        final languageId = await _getLanguageIdByCode(language['code']);
        int finalLanguageId;

        if (languageId != null) {
          finalLanguageId = languageId;
        } else {
          finalLanguageId = await dbHelper.insertLanguage(language['name'], language['code']);
        }

        await dbHelper.insertLanguageForDictionary(dictionaryId, finalLanguageId);
      }

      // Обработка слов и их переводов
      final words = dictionary['words'] ?? [];
      for (var wordData in words) {
        final wordId = await dbHelper.insertWord(dictionaryId);
        for (var translation in wordData['translations']) {
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
  }

  Future<int?> _getLanguageIdByCode(String code) async {
    final dbHelper = await DatabaseHelper.instance;
    final language = await dbHelper.getLanguageByCode(code); // Запрос в БД по коду языка
    return language != null ? language['id'] : null;
  }

  @override
  void initState() {
    super.initState();
    _dictionaries = fetchDictionaries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDFBE8), // Светлый бежевый цвет
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF438589), // Бирюзовый цвет
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: Icon(
                  Icons.person_outline, // Иконка пользователя
                  color: Color(0xFFFDFBE8),
                  size: 30,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            Text('Библиотека',
                style: TextStyle(color: Color(0xFFFDFBE8), fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: FutureBuilder<List<Dictionary>>(
        future: _dictionaries,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Словари отсутствуют'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final dictionary = snapshot.data![index];
                return Card(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: Color(0xFF438589),
                    ),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  color: Color(0xFFFDFBE8),
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(dictionary.name,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dictionary.langChain),
                        SizedBox(height: 4),
                        Text(dictionary.description,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => openOwnerInfoPage(dictionary.owner),
                          child: Text(
                            "Автор: ${dictionary.owner}",
                            style: TextStyle(
                              color: Color(0xFF438589), // Цвет текста владельца
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline, // Подчёркивание
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(dictionary.rating.toString(),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),

                            SizedBox(width: 4), // Отступ между текстом и иконкой
                            Icon(Icons.star, color: Colors.amber, size: 16),
                          ],
                        ),
                        Icon(Icons.cloud_download_outlined, color: Colors.grey),
                      ],
                    ),
                    onTap: () => downloadAndImportDictionary(dictionary.id),
                  ),
                );
              },
            );
          }
        },
      ),
      bottomNavigationBar: CustomBottomAppBar(parentContext: context),
    );
  }

  void openOwnerInfoPage(String ownerName) {
    // Переход на страницу с информацией о владельце
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OwnerInfoPage(ownerName: ownerName),
      ),
    );
  }
}
