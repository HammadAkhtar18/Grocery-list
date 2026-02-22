import 'package:go_router/go_router.dart';
import '../../features/shared/presentation/pages/main_screen.dart';
import '../../features/grocery_list/presentation/pages/list_detail_page.dart';

/// App router configuration using go_router
final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainScreen(),
      routes: [
        GoRoute(
          path: 'list/:id',
          builder: (context, state) {
            final listId = state.pathParameters['id'];
            if (listId == null || listId.isEmpty) {
              return const MainScreen();
            }
            return ListDetailPage(listId: listId);
          },
        ),
      ],
    ),
  ],
);
