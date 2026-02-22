import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/router/router.dart';
import 'features/grocery_list/presentation/bloc/grocery_bloc.dart';
import 'features/pantry/presentation/bloc/pantry_bloc.dart';

/// Main application widget
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<GroceryBloc>(
          create: (context) => GroceryBloc(),
        ),
        BlocProvider<PantryBloc>(
          create: (context) => PantryBloc(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Grocery & Pantry',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
  }
}
