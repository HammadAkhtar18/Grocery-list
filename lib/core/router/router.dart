import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/shared/presentation/pages/main_screen.dart';
import '../../features/grocery_list/presentation/pages/list_detail_page.dart';
import '../../features/grocery_list/presentation/bloc/grocery_detail_bloc.dart';
import '../../features/grocery_list/presentation/bloc/grocery_detail_event.dart';

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
            // Create a fresh GroceryDetailBloc per route navigation.
            // Auto-loads detail on creation. Auto-closed when route pops.
            return BlocProvider<GroceryDetailBloc>(
              create: (context) => GroceryDetailBloc()
                ..add(LoadDetail(listId)),
              child: ListDetailPage(listId: listId),
            );
          },
        ),
      ],
    ),
  ],
);
