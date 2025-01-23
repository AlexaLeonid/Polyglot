import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Для хранения токенов
import 'package:http/http.dart' as http; // Для API-запросов
import 'dart:convert'; // Для декодирования JSON
import '../presentation/DickHub/login_page.dart'; // Страница для входа
import '../presentation/DickHub/my_profile_page.dart';
import 'DickHub/register_page.dart'; // Страница профиля (создадим позже)
import 'dart:io'; // Для работы с файлами
import 'package:path_provider/path_provider.dart'; // Для определения локального пути

class MyDrawer extends StatefulWidget {
  const MyDrawer({Key? key}) : super(key: key);

  @override
  _MyDrawerState createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  String? _username;
  String? _email;
  String? _profilePhoto;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();

    // Загружаем сохранённые данные
    setState(() {
      _username = prefs.getString('username');
      _email = prefs.getString('email');
      _profilePhoto = prefs.getString('profile_photo_path');
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    // Загружаем сохранённые данные
    setState(() {
      _username = prefs.getString('username');
      _email = prefs.getString('email');
      _profilePhoto = prefs.getString('profile_photo_path');
    });

    final token = prefs.getString('access_token');

    if (token != null) {
      try {
        // Получаем обновлённые данные профиля
        final response = await http.get(
          Uri.parse('https://sublimely-many-mule.cloudpub.ru:443/user/profile'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final decodedBody = utf8.decode(response.bodyBytes);
          final data = json.decode(decodedBody);

          // Обновляем данные профиля
          await prefs.setString('username', data['username']);
          await prefs.setString('email', data['email']);
          await prefs.setString('fullname', data['fullname']);
          await prefs.setString('bio', data['bio']);
          setState(() {
            _username = data['username'];
            _email = data['email'];
          });

          // Загружаем фото пользователя
          if (data['username'] != null) {
            await _downloadAndSavePhoto(data['username']);
          }
        } else {
          await _logout();
        }
      } catch (e) {
        print('Ошибка загрузки данных пользователя: $e');
      }
    }
  }

  Future<void> _downloadAndSavePhoto(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse('https://sublimely-many-mule.cloudpub.ru:443/user/photo/$username'),
        );

        if (response.statusCode == 200) {
          final prefs = await SharedPreferences.getInstance();
          final appDir = await getApplicationDocumentsDirectory();
          final profilePhotoDir = Directory('${appDir.path}/profile_photos');

          // Создаём директорию, если её нет
          if (!profilePhotoDir.existsSync()) {
            profilePhotoDir.createSync(recursive: true);
          }

          // Создаём уникальное имя для нового файла
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final newPhotoPath = '${profilePhotoDir.path}/photo_$timestamp.jpg';
          final newPhotoFile = File(newPhotoPath);

          await newPhotoFile.writeAsBytes(response.bodyBytes);

          // Удаляем старое фото
          final oldPhotoPath = prefs.getString('profile_photo_path');
          if (oldPhotoPath != null) {
            final oldFile = File(oldPhotoPath);
            if (oldFile.existsSync()) {
              oldFile.deleteSync();
            }
          }

          // Сохраняем новый путь в SharedPreferences
          await prefs.setString('profile_photo_path', newPhotoFile.path);

          // Обновляем состояние
          setState(() {
            _profilePhoto = newPhotoFile.path;
          });
        }
      } catch (e) {
        print('Ошибка загрузки фото: $e');
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();

    // Удаляем токены из локального хранилища
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');

    // Сбрасываем данные профиля
    await prefs.remove('username');
    await prefs.remove('email');
    await prefs.remove('fullname');
    await prefs.remove('bio');
    await prefs.remove('profile_photo_path');

    // Обновляем состояние приложения
    setState(() {
      _username = null;
      _email = null;
      _profilePhoto = null;
    });

    // Уведомляем пользователя
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Вы вышли из аккаунта.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = _username != null && _email != null;

    return Drawer(
      backgroundColor: const Color(0xFFFDFBE8),
      child: ListView(
        children: <Widget>[
          if (isLoggedIn) ...[
            // Если пользователь авторизован
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              child: UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF438589)),
                accountName: Text(_username ?? 'Имя пользователя'),
                accountEmail: Text(_email ?? 'Электронная почта'),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: _profilePhoto != null
                      ? FileImage(File(_profilePhoto!))
                      : AssetImage('assets/images/placeholder.jpg') as ImageProvider,
                ),
              ),
            ),
            ListTile(
              title: const Text("Профиль"),
              leading: const Icon(Icons.account_circle),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
            ListTile(
              title: const Text("Выход"),
              leading: const Icon(Icons.logout),
              onTap: () async {
                await _logout();
              },
            ),
          ] else ...[
            // Если пользователь НЕ авторизован
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF438589)),
              child: const Center(
                child: Text(
                  'Добро пожаловать!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            ListTile(
              title: const Text("Вход"),
              leading: const Icon(Icons.login),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                ).then((_) => _loadUserData()); // Перезагружаем данные после входа
              },
            ),
            ListTile(
              title: const Text("Регистрация"),
              leading: const Icon(Icons.app_registration),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterPage()),
                );
              },
            ),
          ],
          // Общие элементы меню (например, настройки)
          ListTile(
            title: const Text("Настройки"),
            leading: const Icon(Icons.settings),
            onTap: () {
              // Действие для настроек
            },
          ),
        ],
      ),
    );
  }
}
