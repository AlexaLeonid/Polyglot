import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Для хранения токенов
import 'package:http/http.dart' as http; // Для API-запросов
import 'dart:convert'; // Для декодирования JSON
import '../presentation/DickHub/login_page.dart'; // Страница для входа
import '../presentation/DickHub/profile_page.dart';
import 'DickHub/register_page.dart'; // Страница профиля (создадим позже)

class MyDrawer extends StatefulWidget {
  const MyDrawer({Key? key}) : super(key: key);

  @override
  _MyDrawerState createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  String? _username;
  String? _email;
  String? _profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse('https://sublimely-many-mule.cloudpub.ru:443/user/profile'), // Замените на ваш API-эндпоинт
          headers: {
            'Authorization': 'Bearer $token'
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            _username = data['username'];
            _email = data['email'];
            _profilePhotoUrl = data['photo_url'];
          });
        } else {
          // Если токен недействителен, очищаем локальное хранилище
          await _logout();
        }
      } catch (e) {
        print('Ошибка загрузки данных пользователя: $e');
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token'); // Удаляем токен из хранилища
    await prefs.remove('refresh_token'); // Удаляем refresh токен
    setState(() {
      _username = null;
      _email = null;
      _profilePhotoUrl = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Вы вышли из аккаунта.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFFDFBE8),
      child: ListView(
        children: <Widget>[
          if (_username != null) ...[
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              child: UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF438589)),
                accountName: Text(_username ?? ''),
                accountEmail: Text(_email ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: _profilePhotoUrl != null
                      ? NetworkImage(_profilePhotoUrl!)
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
                  MaterialPageRoute(builder: (context) => ProfilePage()), // Страница профиля
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
                  MaterialPageRoute(builder: (context) => LoginPage()), // Страница входа
                ).then((_) => _loadUserData()); // Перезагружаем данные пользователя после входа
              },
            ),
            ListTile(
              title: const Text("Регистрация"),
              leading: const Icon(Icons.app_registration),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterPage()), // Страница регистрации
                );
              },
            ),
          ],
          ListTile(
            title: const Text("Настройки"),
            leading: const Icon(Icons.settings),
            onTap: () {
              // Открыть страницу настроек
            },
          ),
        ],
      ),
    );
  }
}
