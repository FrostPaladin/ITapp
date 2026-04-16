import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:koto_zayavochnik/shared/widgets/app_text_field.dart';
import 'package:koto_zayavochnik/shared/widgets/app_button.dart';
import 'package:koto_zayavochnik/features/auth/bloc/auth_bloc.dart';
import 'package:koto_zayavochnik/features/auth/bloc/auth_event.dart';
import 'package:koto_zayavochnik/features/auth/bloc/auth_state.dart';


class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          context.go('/home');
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFE8F4FD),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return Column(
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'КРУТОЕ ПРИЛОЖЕНИЕ!!!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.pets, size: 64, color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Создать аккаунт',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Введите свой никнейм, email и пароль',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      hint: 'nickname',
                      controller: _nicknameController,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      hint: 'email@domain.com',
                      controller: _emailController,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      hint: 'password...',
                      obscure: true,
                      controller: _passwordController,
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: 'Регистрация',
                      onTap: () {
                        context.read<AuthBloc>().add(
                          RegisterRequested(
                            _nicknameController.text.trim(),
                            _emailController.text.trim(),
                            _passwordController.text.trim(),
                          ),
                        );
                      },
                      isLoading: state is AuthLoading,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'или',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Уже есть аккаунт? '),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: const Text(
                            'Войти',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Нажимая зарегистрироваться, вы принимаете наши\nTerms of Service и Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}