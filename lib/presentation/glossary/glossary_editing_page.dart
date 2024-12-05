import 'package:flutter/material.dart';
import '../../data/db/database.dart';

class EditDictionaryPage extends StatefulWidget {
  final int dictionaryId; // ID словаря, который нужно редактировать

  EditDictionaryPage({required this.dictionaryId});

  @override
  _EditDictionaryPageState createState() => _EditDictionaryPageState();
}

class _EditDictionaryPageState extends State<EditDictionaryPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<Map<String, dynamic>> _languages = [];
  List<int> _selectedLanguages = [];

  @override
  void initState() {
    super.initState();
    _loadLanguages();
    _loadDictionaryData();
  }

  Future<void> _loadLanguages() async {
    final dbHelper = DatabaseHelper.instance;
    final languages = await dbHelper.fetchLanguages();
    setState(() {
      _languages = languages;
    });
  }

  Future<void> _loadDictionaryData() async {
    final dbHelper = DatabaseHelper.instance;
    final dictionary = await dbHelper.fetchDictionaryById(widget.dictionaryId);
    final selectedLanguages = await dbHelper.fetchDictionaryLanguages(widget.dictionaryId);

    setState(() {
      _nameController.text = dictionary['name'] ?? '';
      _descriptionController.text = dictionary['description'] ?? '';
      _selectedLanguages = selectedLanguages.map<int>((lang) => lang['id'] as int).toList();
    });
  }

  Future<void> _saveChanges() async {
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

      // Обновляем данные словаря
      await dbHelper.updateDictionary(widget.dictionaryId, name, description);

      // Обновляем связанные языки
      await dbHelper.clearLanguagesForDictionary(widget.dictionaryId);
      for (int languageId in _selectedLanguages) {
        await dbHelper.insertLanguageForDictionary(widget.dictionaryId, languageId);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Изменения сохранены')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDFBE8),
      appBar: AppBar(
        backgroundColor: Color(0xFF438589),
        title: Text("Редактирование словаря"),
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
            Text('Выберите языки:', style: TextStyle(fontSize: 16)),
            Expanded(
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
            SizedBox(height: 16),
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
                  onPressed: _saveChanges,
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
