abstract class AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email, password;
  LoginRequested(this.email, this.password);
}

class RegisterRequested extends AuthEvent {
  final String nickname, email, password;
  RegisterRequested(this.nickname, this.email, this.password);
}

class LogoutRequested extends AuthEvent {}

class CheckAuthStatus extends AuthEvent {}