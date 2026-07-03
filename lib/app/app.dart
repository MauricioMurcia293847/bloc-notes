import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'preferences/app_preferences.dart';
import 'theme/app_theme.dart';
import 'theme/theme_mode_controller.dart';

class BlocNotesApp extends ConsumerWidget {
  const BlocNotesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final textSize = ref.watch(textSizeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Bloc',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(textSize.scale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
