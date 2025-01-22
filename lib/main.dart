import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'presentation/home_page.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Инициализация для асинхронного кода
  await _initializeApp();
  runApp(MyApp());
}

Future<void> _initializeApp() async {
  try {
    await _loadProfile();
  } catch (e) {
    debugPrint('Ошибка при инициализации приложения: $e');
  }
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

Future<void> _loadProfile() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  if (token == null) {
    debugPrint('Токен отсутствует');
    await prefs.remove('username');
    await prefs.remove('email');
    return;
  }

  try {
    final response = await http.get(
      Uri.parse('https://sublimely-many-mule.cloudpub.ru:443/user/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      final profileData = json.decode(decodedBody);
      final username = profileData['username'];

      if (username != null) {
        // Обновляем данные профиля
        await prefs.setString('username', profileData['username']);
        await prefs.setString('email', profileData['email']);
        await prefs.setString('fullname', profileData['fullname']);
        await prefs.setString('bio', profileData['bio']);
        await _loadProfilePhoto(username);
      }
    } else {
      debugPrint('Ошибка загрузки профиля: ${response.body}');
    }
  } catch (e) {
    debugPrint('Ошибка при загрузке профиля: $e');
  }
}

Future<void> _loadProfilePhoto(String username) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  if (token == null) {
    debugPrint('Токен отсутствует');
    await prefs.remove('username');
    await prefs.remove('email');
    return;
  }

  try {
    final response = await http.get(
      Uri.parse('https://sublimely-many-mule.cloudpub.ru:443/user/photo/$username'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final appDir = await getApplicationDocumentsDirectory();
      final profilePhotoDir = Directory('${appDir.path}/profile_photos');

      // Создаём директорию, если её нет
      if (!profilePhotoDir.existsSync()) {
        profilePhotoDir.createSync(recursive: true);
      }

      final newPhotoPath = '${profilePhotoDir.path}/photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newPhotoFile = File(newPhotoPath);

      await newPhotoFile.writeAsBytes(response.bodyBytes);

      // Удаляем старое фото
      final oldPhotoPath = prefs.getString('profile_photo_path');
      if (oldPhotoPath != null) {
        final oldFile = File(oldPhotoPath);
        if (oldFile.existsSync()) {
          await oldFile.delete();
        }
      }

      await prefs.setString('profile_photo_path', newPhotoFile.path);
    } else {
      debugPrint('Ошибка загрузки фото: ${response.body}');
    }
  } catch (e) {
    debugPrint('Ошибка при загрузке фото: $e');
  }
}
