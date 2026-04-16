import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:koto_zayavochnik/core/router/app_router.dart';
import 'package:koto_zayavochnik/core/theme/app_theme.dart';
import 'package:koto_zayavochnik/features/auth/bloc/auth_bloc.dart';
import 'package:koto_zayavochnik/features/auth/bloc/auth_event.dart';
import 'package:koto_zayavochnik/features/tickets/bloc/tickets_bloc.dart';
import 'package:koto_zayavochnik/core/api/api_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc(ApiClient())..add(CheckAuthStatus()),
        ),
        BlocProvider(
          create: (context) => TicketsBloc(ApiClient()),
        ),
      ],
      child: MaterialApp.router(
        title: 'Котозаявочник',
        theme: AppTheme.light,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}