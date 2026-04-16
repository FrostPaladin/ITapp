import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  late Dio _dio;
  final _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:3000/api/',
      contentType: 'application/json',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    
    // Лог
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'token');
        print('🔑 Token from storage: ${token != null ? 'Exists (${token.substring(0, token.length > 20 ? 20 : token.length)}...)' : 'NULL'}');
        
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          print(' Token added to request headers');
        } else {
          print(' No token found!');
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        print(' Dio Error: ${error.response?.statusCode} - ${error.response?.data}');
        if (error.response?.statusCode == 401) {
          await _storage.delete(key: 'token');
          await _storage.delete(key: 'user_email');
          await _storage.delete(key: 'user_nickname');
        }
        return handler.next(error);
      },
    ));
  }

  // Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('auth/login', data: {
        'email': email,
        'password': password,
      });
      
      print(' Login response: ${response.data}');
      
      //токен и данные пользователя
      final token = response.data['token'];
      final user = response.data['user'];
      
      if (token != null && token.isNotEmpty) {
        await _storage.write(key: 'token', value: token);
        await _storage.write(key: 'user_email', value: user['email'] ?? email);
        await _storage.write(key: 'user_nickname', value: user['nickname'] ?? email.split('@').first);
        print(' Login successful, token saved: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      } else {
        print(' Login failed: no token in response');
      }
      
      return response.data;
    } on DioException catch (e) {
      print(' Login error: ${e.response?.data}');
      throw Exception(e.response?.data['error'] ?? 'Ошибка входа');
    }
  }

  Future<Map<String, dynamic>> register(String nickname, String email, String password) async {
    try {
      final response = await _dio.post('auth/register', data: {
        'nickname': nickname,
        'email': email,
        'password': password,
      });
      
      print('📥 Register response: ${response.data}');
      
      // Сохраняем токен и данные пользователя
      final token = response.data['token'];
      final user = response.data['user'];
      
      if (token != null && token.isNotEmpty) {
        await _storage.write(key: 'token', value: token);
        await _storage.write(key: 'user_email', value: user['email'] ?? email);
        await _storage.write(key: 'user_nickname', value: user['nickname'] ?? nickname);
        print(' Register successful, token saved: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      } else {
        print(' Register failed: no token in response');
      }
      
      return response.data;
    } on DioException catch (e) {
      print(' Register error: ${e.response?.data}');
      throw Exception(e.response?.data['error'] ?? 'Ошибка регистрации');
    }
  }

  Future<List<Map<String, dynamic>>> getTickets() async {
    try {
      final response = await _dio.get('tickets');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      print(' Get tickets error: ${e.response?.data}');
      throw Exception(e.response?.data['error'] ?? 'Ошибка получения заявок');
    }
  }

  Future<Map<String, dynamic>> getTicketById(String id) async {
    try {
      final response = await _dio.get('tickets/$id');
      return response.data;
    } on DioException catch (e) {
      print(' Get ticket error: ${e.response?.data}');
      throw Exception(e.response?.data['error'] ?? 'Ошибка получения заявки');
    }
  }

  Future<Map<String, dynamic>> createTicket(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('tickets', data: data);
      return response.data;
    } on DioException catch (e) {
      print(' Create ticket error: ${e.response?.data}');
      throw Exception(e.response?.data['error'] ?? 'Ошибка создания заявки');
    }
  }

  Future<Map<String, dynamic>> updateTicket(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('tickets/$id', data: data);
      return response.data;
    } on DioException catch (e) {
      print(' Update ticket error: ${e.response?.data}');
      throw Exception(e.response?.data['error'] ?? 'Ошибка обновления заявки');
    }
  }

  Future<void> deleteTicket(String id) async {
    try {
      await _dio.delete('tickets/$id');
    } on DioException catch (e) {
      print(' Delete ticket error: ${e.response?.data}');
      throw Exception(e.response?.data['error'] ?? 'Ошибка удаления заявки');
    }
  }

  Future<Map<String, dynamic>> addComment(String ticketId, String text) async {
    try {
      final response = await _dio.post('tickets/$ticketId/comments', data: {
        'text': text,
      });
      return response.data;
    } on DioException catch (e) {
      print(' Add comment error: ${e.response?.data}');
      throw Exception(e.response?.data['error'] ?? 'Ошибка добавления комментария');
    }
  }

  Future<List<dynamic>> getCategories() async {
    try {
      final response = await _dio.get('categories');
      return response.data;
    } on DioException catch (e) {
      print(' Get categories error: ${e.response?.data}');
      throw Exception(e.response?.data['error'] ?? 'Ошибка получения категорий');
    }
  }
  Future<Map<String, dynamic>> getProfile() async {
  try {
    final response = await _dio.get('profile');
    return response.data;
  } on DioException catch (e) {
    print(' Get profile error: ${e.response?.data}');
    throw Exception(e.response?.data['error'] ?? 'Ошибка получения профиля');
  }
}

// Обновить профиль
Future<Map<String, dynamic>> updateProfile(String nickname) async {
  try {
    final response = await _dio.put('profile', data: {
      'nickname': nickname,
    });
    return response.data;
  } on DioException catch (e) {
    print(' Update profile error: ${e.response?.data}');
    throw Exception(e.response?.data['error'] ?? 'Ошибка обновления профиля');
  }
}

// Сменить пароль
Future<void> changePassword(String currentPassword, String newPassword) async {
  try {
    await _dio.put('profile/password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  } on DioException catch (e) {
    print(' Change password error: ${e.response?.data}');
    throw Exception(e.response?.data['error'] ?? 'Ошибка смены пароля');
  }
}

// Загрузить аватарку
Future<String> uploadAvatar(String base64Avatar) async {
  try {
    final response = await _dio.post('profile/avatar', data: {
      'avatar': base64Avatar,
    });
    return response.data['avatar'];
  } on DioException catch (e) {
    print(' Upload avatar error: ${e.response?.data}');
    throw Exception(e.response?.data['error'] ?? 'Ошибка загрузки аватарки');
  }
}
  Future<void> logout() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'user_email');
    await _storage.delete(key: 'user_nickname');
    print(' Logout successful, token deleted');
  }
}

