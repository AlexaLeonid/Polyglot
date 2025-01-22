import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image_picker/image_picker.dart'; // Для загрузки фото с устройства
import 'package:http_parser/http_parser.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _username;
  String? _email;
  String? _fullname;
  String? _bio;
  String? _profilePhoto;

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  Future<void> _getProfile() async {
    final prefs = await SharedPreferences.getInstance();

    // Загружаем сохранённые данные
    setState(() {
      _username = prefs.getString('username');
      _email = prefs.getString('email');
      _fullname = prefs.getString('fullname');
      _bio = prefs.getString('bio');
      _profilePhoto = prefs.getString('profile_photo_path');
    });
  }

  Future<void> _updateProfile(String? fullname, String? bio, File? photo) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token != null) {
      try {
        // Формируем URL с параметрами
        final uri = Uri.parse(
          'https://sublimely-many-mule.cloudpub.ru:443/user/profile',
        ).replace(queryParameters: {
          if (fullname != null) 'fullname': fullname,
          if (bio != null) 'bio': bio,
        });

        final request = http.MultipartRequest('PUT', uri);
        request.headers['Authorization'] = 'Bearer $token';

        // Если загружается новое фото
        if (photo != null) {
          // Добавляем файл в запрос
          request.files.add(await http.MultipartFile.fromPath(
            'photo',
            photo.path,
            contentType: MediaType('image', 'jpeg'),
          ));

          // Отправляем запрос на сервер
          final response = await request.send();

          if (response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Профиль успешно обновлен')),
            );

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

            // Копируем файл в новое место
            final newPhotoFile = await photo.copy(newPhotoPath);

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

            // Локально обновляем остальные данные
            setState(() {
              if (fullname != null) _fullname = fullname;
              if (bio != null) _bio = bio;
            });

            // Сохраняем другие данные в SharedPreferences
            if (fullname != null) await prefs.setString('fullname', fullname);
            if (bio != null) await prefs.setString('bio', bio);
          } else {
            final responseBody = await response.stream.bytesToString();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ошибка обновления профиля: $responseBody')),
            );
          }
        }
        else{
          // Отправляем запрос на сервер
          final response = await request.send();

          if (response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Профиль успешно обновлен')),
            );

            // Локально обновляем остальные данные
            setState(() {
              if (fullname != null) _fullname = fullname;
              if (bio != null) _bio = bio;
            });

            // Сохраняем другие данные в SharedPreferences
            if (fullname != null) await prefs.setString('fullname', fullname);
            if (bio != null) await prefs.setString('bio', bio);
          } else {
            final responseBody = await response.stream.bytesToString();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ошибка обновления профиля: $responseBody')),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  void _showEditProfileDialog() async {
    final fullnameController = TextEditingController(text: _fullname);
    final bioController = TextEditingController(text: _bio);
    File? selectedPhoto;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Редактировать профиль'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: fullnameController,
                  decoration: const InputDecoration(labelText: 'Полное имя'),
                ),
                TextField(
                  controller: bioController,
                  decoration: const InputDecoration(labelText: 'О себе'),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

                    if (pickedFile != null) {
                      setState(() {
                        selectedPhoto = File(pickedFile.path);
                      });
                    }
                  },
                  icon: const Icon(Icons.photo),
                  label: const Text('Загрузить фото'),
                ),
                if (selectedPhoto != null) Text('Фото выбрано: ${selectedPhoto!.path}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateProfile(
                  fullnameController.text.isEmpty ? null : fullnameController.text,
                  bioController.text.isEmpty ? null : bioController.text,
                  selectedPhoto,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        backgroundColor: const Color(0xFF438589),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _username == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_profilePhoto != null)
              CircleAvatar(
                radius: 50,
                backgroundImage: _profilePhoto != null
                    ? FileImage(File(_profilePhoto!))
                    : AssetImage('assets/images/placeholder.jpg') as ImageProvider,
              )
            else
              const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/images/placeholder.jpg'),
              ),
            const SizedBox(height: 20),
            Text(
              _fullname ?? _username ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _email ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            if (_bio != null)
              Text(
                _bio!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
          ],
        ),
      ),
    );
  }
}