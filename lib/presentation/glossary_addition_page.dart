import 'package:flutter/material.dart';
import '../data/db/database.dart';

class AddDictionaryPage extends StatefulWidget {
  @override
  _AddDictionaryPageState createState() => _AddDictionaryPageState();
}

class _AddDictionaryPageState extends State<AddDictionaryPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<Map<String, dynamic>> _languages = [];
  List<int> _selectedLanguages = [];

  @override
  void initState() {
    super.initState();
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    final dbHelper = DatabaseHelper.instance;
    final languages = await dbHelper.fetchLanguages();
    setState(() {
      _languages = languages;
    });
  }

  Future<void> _saveDictionary() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Название словаря не может быть пустым')),
      );
      return;
    }

    if (_selectedLanguages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Выберите хотя бы один язык')),
      );
      return;
    }

    try {
      final dbHelper = DatabaseHelper.instance;
      final dictionaryId = await dbHelper.insertDictionary(name, description);

      for (int languageId in _selectedLanguages) {
        await dbHelper.insertLanguageForDictionary(dictionaryId, languageId);
      }

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
      backgroundColor: Color(0xFFFDFBE8), // Светлый бежевый цвет
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
            Text(
              'Выберите языки:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Expanded(
              flex: 3,
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView.builder(
                  itemCount: _languages.length,
                  itemBuilder: (context, index) {
                    final language = _languages[index];
                    return CheckboxListTile(
                      title: Text(language['name']),
                      value: _selectedLanguages.contains(language['id']),
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedLanguages.add(language['id']);
                          } else {
                            _selectedLanguages.remove(language['id']);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
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
                    backgroundColor: Color(0xFF438589),
                  ),
                  child: Icon(
                    Icons.close,
                    color: Color(0xFFFDFBE8),
                    size: 20,
                  ),
                ),

                ElevatedButton(
                  onPressed: _saveDictionary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF438589),
                  ),
                  child: Icon(
                    Icons.done,
                    color: Color(0xFFFDFBE8),
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
