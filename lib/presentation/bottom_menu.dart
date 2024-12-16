import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../data/db/database.dart';
import 'DickHub/dictionary_hub_page.dart';
import 'home_page.dart';

class CustomBottomAppBar extends StatelessWidget {
  final BuildContext parentContext; // Контекст родительского виджета

  const CustomBottomAppBar({required this.parentContext});

  Future<int?> _getLanguageIdByCode(String code) async {
    final dbHelper = await DatabaseHelper.instance;
    final language = await dbHelper.getLanguageByCode(code); // Запрос в БД по коду языка
    return language != null ? language['id'] : null;
  }

  Future<File?> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      return File(result.files.single.path!);
    } else {
      return null;
    }
  }

  Future<void> _importDictionary() async {
    final dbHelper = await DatabaseHelper.instance;

    // Открываем файл импорта
    final file = await _pickFile();
    if (file == null) {
      ScaffoldMessenger.of(parentContext).showSnackBar(
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
    ScaffoldMessenger.of(parentContext).showSnackBar(
      SnackBar(content: Text('Импорт завершен!')),
    );

    // Перезагружаем данные
    // Здесь предполагается, что _loadDictionaries объявлен в родительском классе.
    if (parentContext is State) {
      final state = parentContext as dynamic;
      state._loadDictionaries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 70,
      color: Color(0xFF438589), // Бирюзовый цвет
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(Icons.upload_outlined, color: Color(0xFFFDFBE8), size: 30),
            onPressed: _importDictionary,
          ),
          IconButton(
            icon: Icon(Icons.list_alt_outlined, color: Color(0xFFFDFBE8), size: 30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.cloud_outlined, color: Color(0xFFFDFBE8), size: 30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DictionaryHubPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
