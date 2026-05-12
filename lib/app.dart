import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/router.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class SyncTeamApp extends ConsumerWidget {
  const SyncTeamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SyncTeam',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
