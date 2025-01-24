import 'package:flutter/material.dart';
import '../../data/db/database.dart';

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

  void _showAddLanguageDialog() {
    final _languageNameController = TextEditingController();
    final _languageCodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFDFBE8),
          title: Text('Добавить язык'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _languageNameController,
                decoration: InputDecoration(
                  labelText: 'Название языка',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _languageCodeController,
                decoration: InputDecoration(
                  labelText: 'Код языка',
                  hintText: 'Пример: en, ru, es',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
              ),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = _languageNameController.text.trim();
                final code = _languageCodeController.text.trim();

                if (name.isNotEmpty && code.isNotEmpty) {
                  try {
                    final dbHelper = DatabaseHelper.instance;
                    await dbHelper.insertLanguage(name, code);
                    await _loadLanguages(); // Обновляем список языков
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Язык добавлен')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Все поля обязательны для заполнения')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF438589),
              foregroundColor: Colors.black,
            ),
              child: Text('Добавить'),
            ),
          ],
        );
      },
    );
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDFBE8),
      appBar: AppBar(
        leading: BackButton(
            color: Color(0xFFFDFBE8)
        ),
        backgroundColor: Color(0xFF438589),
        title: Text("Добавление словаря", style: TextStyle(color: Color(0xFFFDFBE8))),
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
                  'Выберите языки:',
                  style: TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: Icon(Icons.add, color: Color(0xFF438589)),
                  onPressed: _showAddLanguageDialog, // Функция для добавления языка
                ),
              ],
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
                      activeColor: Color(0xFF438589),
                      checkColor: Color(0xFFFDFBE8),
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
