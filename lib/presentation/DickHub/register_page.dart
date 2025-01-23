// register_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    final username = _usernameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пожалуйста, заполните все поля.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Запрос на регистрацию
      final registerResponse = await http.post(
        Uri.parse('https://sublimely-many-mule.cloudpub.ru:443/user/'), // Замените на ваш API-эндпоинт
        headers: {
          'Content-Type': 'application/json', // Указываем JSON-заголовок
        },
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
        }), // Передаем тело в формате JSON
      );

      if (registerResponse.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Регистрация успешна.')),
        );

        // После успешной регистрации отправляем запрос на авторизацию
        final loginResponse = await http.post(
          Uri.parse('https://sublimely-many-mule.cloudpub.ru:443/auth/token'), // Замените на ваш API-эндпоинт для авторизации
          body: {
            'username': username,
            'password': password,
          },
        );

        if (loginResponse.statusCode == 200) {
          final data = json.decode(loginResponse.body);
          final prefs = await SharedPreferences.getInstance();

          // Сохраняем токены в SharedPreferences
          await prefs.setString('access_token', data['access_token']);
          await prefs.setString('refresh_token', data['refresh_token']);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Вы успешно вошли в систему.')),
          );

          // Переход на следующий экран или закрытие текущего
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка авторизации: ${loginResponse.body}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка регистрации: ${registerResponse.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDFBE8), // Светлый бежевый цвет
      appBar: AppBar(
        title: Text('Регистрация'),
        backgroundColor: Color(0xFF438589),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Пароль'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF438589),
              ),
              child: Text('Зарегистрироваться'),
            ),
          ],
        ),
      ),
    );
  }
}
