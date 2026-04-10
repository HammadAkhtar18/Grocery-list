import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/router/router.dart';
import 'features/grocery_list/presentation/bloc/grocery_lists_bloc.dart';
import 'features/pantry/presentation/bloc/pantry_bloc.dart';
import 'features/settings/presentation/cubit/app_settings_cubit.dart';
import 'features/settings/presentation/cubit/app_settings_state.dart';

/// Main application widget
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<GroceryListsBloc>(
          create: (context) => GroceryListsBloc(),
        ),
        BlocProvider<PantryBloc>(
          create: (context) => PantryBloc(),
        ),
        BlocProvider<AppSettingsCubit>(
          create: (context) => AppSettingsCubit(
            box: Hive.box<dynamic>(AppConstants.appSettingsBox),
          ),
        ),
      ],
      child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
        builder: (context, state) {
          return MaterialApp.router(
            title: 'Grocery & Pantry',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
