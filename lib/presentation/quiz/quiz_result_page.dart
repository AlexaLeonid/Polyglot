import 'package:flutter/material.dart';
import 'quiz_play_page.dart';
import '../bottom_menu.dart';

class QuizResultPage extends StatelessWidget {
  final int correctCount;
  final int totalAnswers;
  final List<int> selectedDictionaries;

  QuizResultPage({required this.correctCount, required this.totalAnswers, required this.selectedDictionaries});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDFBE8), // Мягкий бежевый фон
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF438589), // Бирюзовый цвет
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Тренировка',
                style: TextStyle(color: Color(0xFFFDFBE8), fontSize: 22, fontWeight: FontWeight.bold)),
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: Color(0xFFFDFBE8), // Бежевый цвет для кнопки Play
                size: 28,
              ),
              onPressed: () {
                // Переход на страницу QuizPlay с выбранными словарями
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        QuizPlayPage(
                          selectedDictionaries: selectedDictionaries,
                        ),
                  ),
                );
              },
            ),
          ],
        ),

      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Отлично!', // Заголовок
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Правильных ответов', // Подзаголовок
              style: TextStyle(
                fontSize: 18,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '$correctCount', // Количество правильных ответов
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Ошибок', // Подзаголовок
              style: TextStyle(
                fontSize: 18,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '${totalAnswers - correctCount}', // Количество ошибок
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomAppBar(parentContext: context),
    );
  }
}