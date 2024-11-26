import 'package:flutter/material.dart';
import '../data/db/database.dart';
import 'dictionary_page.dart';
import 'glossary_addition_page.dart';
import 'quiz.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDFBE8), // Светлый бежевый цвет
      appBar: AppBar(
        backgroundColor: Color(0xFF438589), // Бирюзовый цвет
        title: SizedBox.shrink(), // Убираем текст в AppBar
        leading: Icon(
          Icons.person_outline, // Иконка пользователя
          color: Color(0xFFFDFBE8),
        ),
      ),
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
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Удалить'),
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
                        }, //родип окнесоК
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

      bottomNavigationBar: BottomAppBar(
        color: Color(0xFF438589), // Бирюзовый цвет
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.extension, color: Color(0xFFFDFBE8)),
              onPressed: () {
                // Переход на страницу quiz.dart
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => QuizPage()),
                ); // Замените Quiz() на ваш виджет
              },
            ),
            IconButton(
              icon: Icon(Icons.list, color: Color(0xFFFDFBE8)),
              onPressed: () {
                // Переход на страницу quiz.dart
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.download, color: Color(0xFFFDFBE8)),
              onPressed: () {},
            ),
          ],
        ),
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