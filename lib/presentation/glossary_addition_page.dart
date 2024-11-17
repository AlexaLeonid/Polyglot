import 'package:flutter/material.dart';
import '../data/db/database.dart';


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