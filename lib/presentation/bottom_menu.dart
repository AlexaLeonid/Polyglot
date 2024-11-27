import 'package:flutter/material.dart';
import 'home_page.dart';
import 'quiz/quiz_start_page.dart';

class CustomBottomAppBar extends StatelessWidget {
  final BuildContext context;

  const CustomBottomAppBar({required this.context});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Color(0xFF438589), // Бирюзовый цвет
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(Icons.extension, color: Color(0xFFFDFBE8)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => QuizPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.list, color: Color(0xFFFDFBE8)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.download, color: Color(0xFFFDFBE8)),
            onPressed: () {
              // Логика загрузки (оставьте пустым или добавьте вашу функциональность)
            },
          ),
        ],
      ),
    );
  }
}