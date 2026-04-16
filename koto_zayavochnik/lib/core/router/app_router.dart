import 'package:go_router/go_router.dart';
import 'package:koto_zayavochnik/features/auth/screens/log_in_screen.dart';
import 'package:koto_zayavochnik/features/auth/screens/sign_in_screen.dart';
import 'package:koto_zayavochnik/features/tickets/screens/home_screen.dart';
import 'package:koto_zayavochnik/features/tickets/screens/new_task_screen.dart';
import 'package:koto_zayavochnik/features/tickets/screens/task_screen.dart';
import 'package:koto_zayavochnik/features/tickets/screens/category_tickets_screen.dart';
import 'package:koto_zayavochnik/features/tickets/screens/all_tickets_screen.dart';
import 'package:koto_zayavochnik/features/profile/screens/profile_screen.dart';
import 'package:koto_zayavochnik/shared/widgets/bottom_nav_bar.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    // Auth routes
    GoRoute(
      path: '/signin',
      name: 'signin',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LogInScreen(),
    ),
    
    // Main shell with bottom nav
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              name: 'profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    
    // Ticket routes
    GoRoute(
      path: '/new-task',
      name: 'new-task',
      builder: (context, state) => const NewTaskScreen(),
    ),
    GoRoute(
      path: '/task/:id',
      name: 'task',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return TaskScreen(id: id);
      },
    ),
    
    // Category routes
    GoRoute(
      path: '/task-list/:category',
      name: 'task-list',
      builder: (context, state) {
        final category = state.pathParameters['category'] ?? 'Все';
        return CategoryTicketsScreen(category: category);
      },
    ),
    GoRoute(
      path: '/all-tickets',
      name: 'all-tickets',
      builder: (context, state) => const AllTicketsScreen(),
    ),
  ],
);