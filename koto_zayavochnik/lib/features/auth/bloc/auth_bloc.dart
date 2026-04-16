import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:koto_zayavochnik/core/api/api_client.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiClient _api;
  final _storage = const FlutterSecureStorage();
  
  AuthBloc(this._api) : super(AuthInitial()) {
    // Проверяем статус авторизации при запуске
    on<CheckAuthStatus>((event, emit) async {
      final token = await _storage.read(key: 'token');
      if (token != null && token.isNotEmpty) {
        print('✅ AuthBloc: Token found, user is authenticated');
        emit(AuthSuccess(token));
      } else {
        print('❌ AuthBloc: No token found');
        emit(AuthInitial());
      }
    });
    
    on<LoginRequested>((event, emit) async {
  emit(AuthLoading());
  try {
    print('📝 AuthBloc: Login attempt for ${event.email}');
    final data = await _api.login(event.email, event.password);
    final token = data['token'];
    
    print('✅ AuthBloc: Login successful, token: ${token != null ? token.substring(0, token.length > 20 ? 20 : token.length) : "NULL"}...');
    
    // Дополнительная проверка сохранения
    final savedToken = await _storage.read(key: 'token');
    print('🔑 Verified token in storage: ${savedToken != null ? "SAVED" : "NOT SAVED"}');
    
    emit(AuthSuccess(token));
  } catch (e) {
    print('❌ AuthBloc: Login failed - $e');
    emit(AuthFailure(e.toString()));
  }
});
    
    on<RegisterRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        print('📝 AuthBloc: Register attempt for ${event.email}');
        final data = await _api.register(event.nickname, event.email, event.password);
        final token = data['token'];
        
        await _storage.write(key: 'token', value: token);
        await _storage.write(key: 'user_email', value: event.email);
        await _storage.write(key: 'user_nickname', value: event.nickname);
        
        print('✅ AuthBloc: Register successful, token saved');
        emit(AuthSuccess(token));
      } catch (e) {
        print('❌ AuthBloc: Register failed - $e');
        emit(AuthFailure(e.toString()));
      }
    });
    
    on<LogoutRequested>((event, emit) async {
      await _api.logout();
      emit(AuthInitial());
    });
  }
}