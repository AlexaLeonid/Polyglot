import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

import '../../data/db/database.dart';

class OwnerInfoPage extends StatefulWidget {
  final String ownerName;

  const OwnerInfoPage({Key? key, required this.ownerName}) : super(key: key);

  @override
  State<OwnerInfoPage> createState() => _OwnerInfoPageState();
}

class _OwnerInfoPageState extends State<OwnerInfoPage> {
  late Future<UserProfile> _userProfile;
  late Future<List<Dictionary>> _userDictionaries;

  @override
  void initState() {
    super.initState();
    _userProfile = fetchUserProfile(widget.ownerName);
    _userDictionaries = fetchUserDictionaries(widget.ownerName);
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

  Future<UserProfile> fetchUserProfile(String username) async {
    final profileResponse = await http.get(
      Uri.parse('https://sublimely-many-mule.cloudpub.ru/user/profile/$username'),
    );

    if (profileResponse.statusCode == 200) {
      final decodedBody = utf8.decode(profileResponse.bodyBytes);
      final profileData = json.decode(decodedBody);
      return UserProfile.fromJson(profileData);
    } else {
      throw Exception('Ошибка загрузки профиля');
    }
  }

  Future<List<Dictionary>> fetchUserDictionaries(String username) async {
    final dictionariesResponse = await http.get(
      Uri.parse('https://sublimely-many-mule.cloudpub.ru/dictionaries/user/$username'),
    );

    if (dictionariesResponse.statusCode == 200) {
      final decodedBody = utf8.decode(dictionariesResponse.bodyBytes);
      final List<dynamic> dictionariesData = json.decode(decodedBody);
      return dictionariesData.map((e) => Dictionary.fromJson(e)).toList();
    } else {
      throw Exception('Ошибка загрузки словарей');
    }
  }

  String getUserPhotoUrl(String username) {
    return 'https://sublimely-many-mule.cloudpub.ru/user/photo/$username';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDFBE8), // Светлый бежевый цвет
      appBar: AppBar(
        title: Text('Информация об авторе'),
        backgroundColor: Color(0xFF438589), // Бирюзовый цвет
      ),
      body: FutureBuilder<UserProfile>(
        future: _userProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final user = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Фото пользователя с анимацией загрузки
                FutureBuilder(
                  future: precacheImage(NetworkImage(getUserPhotoUrl(user.username)), context),
                  builder: (context, imageSnapshot) {
                    if (imageSnapshot.connectionState == ConnectionState.done) {
                      return CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(getUserPhotoUrl(user.username)),
                      );
                    } else {
                      return CircleAvatar(
                        radius: 50,
                        child: CircularProgressIndicator(),
                      );
                    }
                  },
                ),
                SizedBox(height: 16),
                // Полное имя
                Text(
                  user.fullname,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                // Имя пользователя
                Text(
                  '@${user.username}',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                // Описание (био)
                Text(
                  user.bio,
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                // Список словарей
                Expanded(
                  child: FutureBuilder<List<Dictionary>>(
                    future: _userDictionaries,
                    builder: (context, dictSnapshot) {
                      if (dictSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (dictSnapshot.hasError) {
                        return Center(child: Text('Ошибка: ${dictSnapshot.error}'));
                      } else if (dictSnapshot.hasData && dictSnapshot.data!.isNotEmpty) {
                        final dictionaries = dictSnapshot.data!;
                        return ListView.builder(
                          itemCount: dictionaries.length,
                          itemBuilder: (context, index) {
                            final dictionary = dictionaries[index];
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
                                title: Text(
                                  dictionary.name,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(dictionary.langChain),
                                    SizedBox(height: 4),
                                    Text(dictionary.description,
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
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
                      } else {
                        return Center(child: Text('Словари отсутствуют'));
                      }
                    },
                  ),
                ),
              ],
            );
          } else {
            return Center(child: Text('Пользователь не найден'));
          }
        },
      ),
    );
  }
}

class UserProfile {
  final String fullname;
  final String username;
  final String bio;

  UserProfile({
    required this.fullname,
    required this.username,
    required this.bio,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullname: json['fullname'],
      username: json['username'],
      bio: json['bio'],
    );
  }
}

class Dictionary {
  final int id;
  final String name;
  final String langChain;
  final double rating;
  final String description;

  Dictionary({
    required this.id,
    required this.name,
    required this.langChain,
    required this.rating,
    required this.description,
  });

  factory Dictionary.fromJson(Map<String, dynamic> json) {
    return Dictionary(
      id: json['id'],
      name: json['name'],
      langChain: json['lang_chain'],
      rating: (json['rating'] as num).toDouble(),
      description: json['description'],
    );
  }
}
