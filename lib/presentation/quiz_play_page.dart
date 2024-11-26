import 'package:flutter/material.dart';
import '../data/db/database.dart';

class QuizPlayPage extends StatefulWidget {
  final List<int> selectedDictionaries;

  QuizPlayPage({required this.selectedDictionaries});

  @override
  _QuizPlayPageState createState() => _QuizPlayPageState();
}

class _QuizPlayPageState extends State<QuizPlayPage> {
  late Future<Map<int, Map<String, Map<String, List<String>>>>> _futureDictionaries;
  Map<String, TextEditingController> controllers = {}; // Контроллеры для ввода текста
  int currentWordIndex = 0; // Индекс текущего слова для теста
  String? currentWordId;
  String? firstTranslation;
  String? firstTranslationLanguage;
  Map<String, List<String>>? remainingTranslationsByLanguage;
  List<String> userAnswers = []; // Список для ответов пользователя

  @override
  void initState() {
    super.initState();
    _futureDictionaries = DatabaseHelper.instance.fetchDictionaryOfDictionariesWithLanguages(widget.selectedDictionaries);
  }

  // Загружаем следующее слово и его переводы
  void _loadNextWord() {
    if (currentWordIndex < allWords.length) {
      final wordEntry = allWords[currentWordIndex];
      currentWordId = wordEntry.keys.first;
      final translationsByLanguage = wordEntry.values.first;

      // Берем первый перевод для отображения
      final firstEntry = translationsByLanguage.entries.first;
      firstTranslationLanguage = firstEntry.key;
      firstTranslation = firstEntry.value.first;

      // Убираем первый перевод из оставшихся
      remainingTranslationsByLanguage = {};
      translationsByLanguage.forEach((language, translations) {
        if (language == firstTranslationLanguage) {
          if (translations.length > 1) {
            remainingTranslationsByLanguage![language] = translations.sublist(1);
          }
        } else {
          remainingTranslationsByLanguage![language] = translations;
        }
      });

      // Очищаем старые контроллеры и создаем новые для каждого перевода
      controllers.clear();
      remainingTranslationsByLanguage?.forEach((language, translations) {
        for (var translation in translations) {
          controllers[translation] = TextEditingController();
        }
      });
    }
  }

  void _checkAnswers() {
    if (remainingTranslationsByLanguage == null) return;

    int correctCount = 0; // Количество правильных ответов
    int totalAnswers = 0; // Общее количество переводов для ввода

    remainingTranslationsByLanguage!.forEach((language, translations) {
      for (var translation in translations) {
        final userAnswer = controllers[translation]?.text.trim() ?? '';
        totalAnswers++;
        if (userAnswer.toLowerCase() == translation.toLowerCase()) {
          correctCount++;
        }
      }
    });

    // Вывод результата проверки
    if (correctCount == totalAnswers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Отлично! Все переводы для "$currentWordId" правильные.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Некоторые переводы неправильные: $correctCount из $totalAnswers верные.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }

    // Переход к следующему слову
    setState(() {
      currentWordIndex++;
      if (currentWordIndex < allWords.length) {
        _loadNextWord();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Вы завершили тест. Отличная работа!')),
        );
      }
    });
  }

  List<Map<String, Map<String, List<String>>>> allWords = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDFBE8), // Мягкий бежевый фон
      appBar: AppBar(
        backgroundColor: Color(0xFF438589), // Цвет заголовка
        title: Text('Крокодил', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<int, Map<String, Map<String, List<String>>>>>(
        future: _futureDictionaries,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Нет данных для отображения.'));
          } else {
            final dictionaries = snapshot.data!;
            allWords = dictionaries.entries.expand((e) {
              return e.value.entries.map((entry) {
                return {entry.key: entry.value};
              });
            }).toList();

            // Загружаем первое слово и его переводы
            if (currentWordIndex == 0) {
              _loadNextWord();
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (firstTranslation != null && firstTranslationLanguage != null)...[
                    Center(
                      child: Column(
                          children: [Text(
                            firstTranslation!,
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                            Text(
                              '(${firstTranslationLanguage})',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                            ),
                          ]
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children: remainingTranslationsByLanguage!.entries.map((entry) {
                          final language = entry.key;
                          final translations = entry.value;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var translation in translations)
                                Container(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Color(0xFF438589)),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        language,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF438589),
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: TextField(
                                          controller: controllers[translation],
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            hintText: 'Введите перевод...',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF438589),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _checkAnswers,
                    child: Text(
                      'Проверить',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
