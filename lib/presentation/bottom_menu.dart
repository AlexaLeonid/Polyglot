import 'package:flutter/material.dart';
import 'home_page.dart';

class CustomBottomAppBar extends StatelessWidget {
  final BuildContext context;
  final Future<void> Function()? importDictionary; // Сделаем параметр необязательным

  const CustomBottomAppBar({required this.context, this.importDictionary});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 70,
      color: Color(0xFF438589), // Бирюзовый цвет
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(Icons.upload_outlined, color: Color(0xFFFDFBE8), size: 30,),
            onPressed: () {
              if (importDictionary != null) {
                importDictionary!(); // Вызываем переданную функцию, если она есть
              } else {
                // Логика по умолчанию, если функции нет
                print('Импорт не доступен');
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.list_alt_outlined, color: Color(0xFFFDFBE8), size: 30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.cloud_outlined, color: Color(0xFFFDFBE8), size: 30),
            onPressed: () {
              // if (importDictionary != null) {
              //   importDictionary!(); // Вызываем переданную функцию, если она есть
              // } else {
              //   // Логика по умолчанию, если функции нет
              //   print('Импорт не доступен');
              // }
            },
          ),
        ],
      ),
    );
  }
}