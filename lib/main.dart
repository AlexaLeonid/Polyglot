import 'package:flutter/material.dart';

import 'data/db/database.dart';

void main() {
  runApp( MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

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
      _dictionariesFuture = DatabaseHelper.instance.database.then((db) {
        return db.query('dictionaries');
      });
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
          color: Colors.white,
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
                  margin: EdgeInsets.only(bottom: 16.0),
                  child: ListTile(
                    title: Text(dictionary['name'] ?? 'Без названия'),
                    subtitle: Text(dictionary['description'] ?? 'Нет описания'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deleteDictionary(dictionary['id']);
                        }
                        // Можно добавить дополнительные действия, например, редактирование
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Удалить'),
                        ),
                      ],
                    ),
                    onTap: () {
                      // Здесь можно открыть подробности словаря
                      print('Открыть словарь: ${dictionary['name']}');
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
      bottomNavigationBar: BottomAppBar(
        color: Color(0xFF438589), // Бирюзовый цвет
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.extension, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.list, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.download, color: Colors.white),
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

class AddDictionaryPage extends StatefulWidget {
  @override
  _AddDictionaryPageState createState() => _AddDictionaryPageState();
}

class _AddDictionaryPageState extends State<AddDictionaryPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  int languageCount = 3;

  Future<void> _saveDictionary() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Название словаря не может быть пустым')),
      );
      return;
    }

    // Сохраняем словарь в базу данных
    try {
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.insertDictionary(
        name,
        description,
        null, // Временно передаём null для `word_of_chain_id`
        languageCount,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Словарь успешно добавлен')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сохранении словаря: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF438589),
        title: Text("Добавление словаря"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Название словаря',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Описание',
                hintText: '(Необязательно)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Количество языков',
                  style: TextStyle(fontSize: 16),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () {
                        setState(() {
                          if (languageCount > 1) languageCount--;
                        });
                      },
                    ),
                    Text(
                      '$languageCount',
                      style: TextStyle(fontSize: 18),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          languageCount++;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey),
                  ),
                  child: Text(
                    'Отмена',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                ElevatedButton(
                  onPressed: _saveDictionary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF438589),
                  ),
                  child: Text('Создать'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
