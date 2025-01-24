import 'package:shared_preferences/shared_preferences.dart';

import 'quiz/quiz_start_page.dart';

import 'side_menu.dart';
import 'package:flutter/material.dart';
import '../data/db/database.dart';
import 'glossary/dictionary_page.dart';
import 'glossary/glossary_addition_page.dart';
import 'glossary/glossary_editing_page.dart';
import 'dart:io'; // Для работы с файлами
import 'package:path_provider/path_provider.dart'; // Для получения директории
import 'package:share_plus/share_plus.dart';
import 'bottom_menu.dart';
import 'package:http/http.dart' as http;

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

  Future<void> _sendToDictionaryHub(Map<String, dynamic> dictionary, bool isPrivate) async {
    final dbHelper = await DatabaseHelper.instance;
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('access_token');

    try {
      // Генерация JSON файла с помощью существующего метода
      final jsonExport = await dbHelper.exportSpecificDictionariesToJson([dictionary['id']]);

      // Получение пути для временного хранения файла
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/${dictionary["name"]}.json');
      await file.writeAsString(jsonExport);

      if (token != null) {
        // Создание запроса
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('https://sublimely-many-mule.cloudpub.ru:443/dictionaries/'), // Замените на ваш реальный URL
        );

        // Добавление полей формы
        request.headers['Authorization'] = 'Bearer $token';
        request.fields['name'] = dictionary['name'];
        request.fields['lang_chain'] = dictionary['language_codes'];
        request.fields['description'] = dictionary['description'];
        request.fields['is_private'] = isPrivate.toString();

        // Прикрепление файла
        request.files.add(await http.MultipartFile.fromPath('file', file.path));

        // Выполнение запроса
        final response = await request.send();

        if (response.statusCode == 200) {
          // Успешный ответ
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Словарь успешно отправлен в DictionaryHub!')),
          );
        } else {
          // Обработка ошибок
          final responseBody = await response.stream.bytesToString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка при отправке: $responseBody')),
          );
        }
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Вы не авторизованы! Регистрируйся, пока по жопе не дали')),
        );
      }
    } catch (e) {
      // Обработка исключений
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
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
                  Icons.menu,
                  color: Color(0xFFFDFBE8),
                  size: 25,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            Text('Ваши словари',
                style: TextStyle(color: Color(0xFFFDFBE8), fontSize: 22, fontWeight: FontWeight.bold)),
            IconButton(
              icon: Icon(Icons.extension_outlined, color: Color(0xFFFDFBE8), size: 30),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QuizPage()),
                );
              },
            ),
          ],
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
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: Color(0xFF438589), //<-- SEE HERE
                        ),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      color: Color(0xFFFDFBE8),
                      margin: EdgeInsets.only(bottom: 16.0),
                      child: ListTile(
                        title: Text(dictionary['name'] ?? 'Без названия',
                            style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
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
                        trailing: Theme(
                          data: Theme.of(context).copyWith(
                            popupMenuTheme: PopupMenuThemeData(
                              color: Color(0xFFFFFBE6), // Фон для всплывающего меню
                            ),
                          ),
                          child: PopupMenuButton<String>(
                            child: Container(
                              height: 36,
                              width: 48,
                              alignment: Alignment.topRight,
                              child: Icon(
                                Icons.more_vert,
                              ),
                            ),
                            onSelected: (value) async {
                              if (value == 'delete') {
                                _ConfirmDeletingForm(dictionary['id']);
                              } else if (value == 'export') {
                                await _exportDictionary(dictionary['id']);
                              } else if (value == 'edit') {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => EditDictionaryPage(dictionaryId: dictionary['id'])),
                                );
                                _loadDictionaries(); // Перезагружаем список после изменения
                              } else if (value == 'send_to_hub') {
                                final isPrivate = await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      backgroundColor: Color(0xFFFDFBE8),
                                      title: Text('Сделать словарь приватным?'),
                                      content: Text('Приватные словари будут видны только вам.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false), // Не приватный
                                          child: Icon(
                                            Icons.close,
                                            color: Color(0xFF438589),
                                            size: 30,
                                            ),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true), // Приватный
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

                                if (isPrivate != null) {
                                  await _sendToDictionaryHub(dictionary, isPrivate);
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text(
                                  'Изменить',
                                  style: TextStyle(color: Colors.black), // Цвет текста
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  'Удалить',
                                  style: TextStyle(color: Colors.black), // Цвет текста
                                ),
                              ),
                              PopupMenuItem(
                                value: 'export',
                                child: Text(
                                  'Экспортировать',
                                  style: TextStyle(color: Colors.black), // Цвет текста
                                ),
                              ),
                              PopupMenuItem(
                                value: 'send_to_hub',
                                child: Text(
                                  'Отправить в DictionaryHub',
                                  style: TextStyle(color: Colors.black), // Цвет текста
                                ),
                              ),
                            ],
                          ),
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
        parentContext: context, // Передаем контекст родителя
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
        child: Icon(Icons.add, color: Color(0xFFFDFBE8)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );

  }
  Future<void> _deleteDictionary(int dictionaryId) async {
    final dbHelper = await DatabaseHelper.instance;
    await dbHelper.deleteDictionary(dictionaryId);
    _loadDictionaries(); // Обновляем список после удаления
  }

  Future<void> _ConfirmDeletingForm(int dictionaryId) async {

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFDFBE8),
          title: const Text('Вы действительно хотите удалить глоссарий?', style: TextStyle(fontSize: 18),),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
              width: 70.0, // Set your desired width
              height: 30.0, // Set your desired height
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF438589),
                  ),
                  child: Icon(
                    Icons.close,
                    color: Color(0xFFFDFBE8),
                    size: 17,
                  ),
                ),
              ),
              SizedBox(
              width: 70.0, // Set your desired width
              height: 30.0, // Set your desired height
                 child: ElevatedButton(
                    onPressed: (){
                      Navigator.pop(context);
                      _deleteDictionary(dictionaryId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF438589),
                    ),
                    child: Icon(
                      Icons.done,
                      color: Color(0xFFFDFBE8),
                      size: 17,
                    ),
                  ),
              ),
            ],
          ),
        );
      },
    );
  }
}


