import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:koto_zayavochnik/core/api/api_client.dart';
import 'package:koto_zayavochnik/features/auth/bloc/auth_bloc.dart';
import 'package:koto_zayavochnik/features/auth/bloc/auth_event.dart';
import 'package:koto_zayavochnik/shared/widgets/app_button.dart';

import 'dart:html' as html;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storage = const FlutterSecureStorage();
  final ApiClient _api = ApiClient();
  
  String _email = '';
  String _nickname = '';
  String? _avatarBase64;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isChangingPassword = false;
  
  final _nicknameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _api.getProfile();
      setState(() {
        _email = profile['email'];
        _nickname = profile['nickname'];
        _avatarBase64 = profile['avatar'];
        _nicknameController.text = _nickname;
        _isLoading = false;
      });
      
      await _storage.write(key: 'user_email', value: _email);
      await _storage.write(key: 'user_nickname', value: _nickname);
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => _isLoading = false);
      _showSnackBar('Ошибка загрузки профиля: $e');
    }
  }

  // Метод для выбора изображения в вебе
Future<void> _pickImageWeb() async {
  // Создаем input элемент
  final html.FileUploadInputElement input = html.FileUploadInputElement();
  input..accept = 'image/*' ..multiple = false;
  
  input.onChange.listen((event) async {
    final files = input.files;
    if (files != null && files.isNotEmpty) {
      final file = files.first;
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      
      reader.onLoadEnd.listen((event) async {
        // Получаем base64 строку
        String base64String = reader.result as String;
        // Убираем префикс "data:image/...;base64,"
        final base64Image = base64String.split(',').last;
        
        setState(() => _isLoading = true);
        try {
          final avatarUrl = await _api.uploadAvatar(base64Image);
          setState(() {
            _avatarBase64 = avatarUrl;
            _isLoading = false;
          });
          _showSnackBar('Аватарка обновлена!');
        } catch (e) {
          setState(() => _isLoading = false);
          _showSnackBar('Ошибка: $e');
        }
      });
    }
  });
  
  input.click();
}

  // Метод для выбора изображения на мобильных устройствах
  Future<void> _pickImageMobile() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      
      if (image != null) {
        final File imageFile = File(image.path);
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);
        
        setState(() => _isLoading = true);
        
        final avatarUrl = await _api.uploadAvatar(base64Image);
        setState(() {
          _avatarBase64 = avatarUrl;
          _isLoading = false;
        });
        
        _showSnackBar('Аватарка обновлена!');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Ошибка загрузки изображения: $e');
      print('Error picking image: $e');
    }
  }

  // Главный метод выбора изображения (автоматически выбирает платформу)
  Future<void> _pickImage() async {
    if (kIsWeb) {
      await _pickImageWeb();
    } else {
      await _pickImageMobile();
    }
  }

  Future<void> _saveChanges() async {
    if (_nicknameController.text.trim().isEmpty) {
      _showSnackBar('Введите никнейм');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_nicknameController.text != _nickname) {
        final updated = await _api.updateProfile(_nicknameController.text);
        setState(() => _nickname = updated['nickname']);
        await _storage.write(key: 'user_nickname', value: _nickname);
      }

      setState(() => _isEditing = false);
      _showSnackBar('Профиль обновлен!');
    } catch (e) {
      _showSnackBar('Ошибка: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar('Пароли не совпадают');
      return;
    }
    
    if (_newPasswordController.text.length < 4) {
      _showSnackBar('Пароль должен быть не менее 4 символов');
      return;
    }
    
    if (_currentPasswordController.text.isEmpty) {
      _showSnackBar('Введите текущий пароль');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _api.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );
      
      setState(() {
        _isChangingPassword = false;
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
      
      _showSnackBar('Пароль успешно изменен!');
    } catch (e) {
      _showSnackBar('Ошибка: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'user_email');
    await _storage.delete(key: 'user_nickname');
    context.read<AuthBloc>().add(LogoutRequested());
    context.go('/login');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактирование' : 'Профиль'),
        actions: [
          if (!_isEditing && !_isChangingPassword)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Avatar
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _avatarBase64 != null && _avatarBase64!.isNotEmpty
                              ? MemoryImage(base64Decode(_avatarBase64!))
                              : null,
                          child: _avatarBase64 == null || _avatarBase64!.isEmpty
                              ? const Icon(Icons.person, size: 60, color: Colors.grey)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (_isEditing) ...[
                    _buildTextField(
                      controller: _nicknameController,
                      label: 'Никнейм',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                                _nicknameController.text = _nickname;
                              });
                            },
                            child: const Text('Отмена'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppButton(
                            label: 'Сохранить',
                            onTap: _saveChanges,
                            isLoading: _isLoading,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                          _isChangingPassword = true;
                        });
                      },
                      child: const Text('Сменить пароль'),
                    ),
                  ] else if (_isChangingPassword) ...[
                    _buildTextField(
                      controller: _currentPasswordController,
                      label: 'Текущий пароль',
                      icon: Icons.lock_outline,
                      obscure: true,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _newPasswordController,
                      label: 'Новый пароль',
                      icon: Icons.lock_outline,
                      obscure: true,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: 'Подтвердите пароль',
                      icon: Icons.lock_outline,
                      obscure: true,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _isChangingPassword = false;
                                _currentPasswordController.clear();
                                _newPasswordController.clear();
                                _confirmPasswordController.clear();
                              });
                            },
                            child: const Text('Отмена'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppButton(
                            label: 'Сменить пароль',
                            onTap: _changePassword,
                            isLoading: _isLoading,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      _nickname,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _email,
                      style: const TextStyle(color: Colors.black45, fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _InfoRow(label: 'Email', value: _email),
                          const Divider(),
                          _InfoRow(label: 'Никнейм', value: _nickname),
                          const Divider(),
                          _InfoRow(label: 'Статус', value: 'Активен'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.exit_to_app, color: Colors.red),
                        label: const Text('Выйти', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  
  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black45)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}