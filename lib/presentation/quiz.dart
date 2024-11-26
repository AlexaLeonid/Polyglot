import 'package:flutter/material.dart';
import '../data/db/database.dart';
import 'home_page.dart';
import 'quiz_play_page.dart';

class QuizPage extends StatefulWidget {
  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late Future<List<Map<String, dynamic>>> _dictionariesFuture;
  List<Map<String, dynamic>> _dictionaries = []; // Локальный список словарей
  List<int> selectedDictionaries = [];

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
      backgroundColor: Color(0xFFFDFBE8),
      appBar: AppBar(
        automaticallyImplyLeading: false,
          backgroundColor: Color(0xFF438589), // Бирюзовый цвет
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.person_outline,
                color: Color(0xFFFDFBE8), // Бежевый цвет для иконки
                size: 28,
              ),
              IconButton(
                icon: Icon(
                  Icons.play_arrow,
                  color: Color(0xFFFDFBE8), // Бежевый цвет для кнопки Play
                  size: 32,
                ),
                onPressed: () {
                  if (selectedDictionaries.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Выберите хотя бы один словарь")),
                    );
                    return;
                  }

                  // Переход на страницу QuizPlay с выбранными словарями
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizPlayPage(
                        selectedDictionaries: selectedDictionaries,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

        ),
      body: Column(
        children: [
          Container(
            alignment: Alignment.bottomLeft,
            padding: EdgeInsets.only(left: 16, bottom: 8, top: 8),
            child: Text(
              "Выберите словарь для тренировки",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
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
                  _dictionaries = snapshot.data!;
                  return ListView.builder(
                    padding: EdgeInsets.all(16.0),
                    itemCount: _dictionaries.length,
                    itemBuilder: (context, index) {
                      final dictionary = _dictionaries[index];
                      final isSelected = selectedDictionaries.contains(dictionary['id']);

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
                                  dictionary['language_codes'],
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                            ],
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedDictionaries.add(dictionary['id']);
                                } else {
                                  selectedDictionaries.remove(dictionary['id']);
                                }
                              });
                            },
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
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
    );
  }
}