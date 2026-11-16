import 'package:flutter/material.dart';
import 'package:smartcart/app_router.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';

class SmartCartApp extends StatelessWidget {
  const SmartCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartCart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: ColoresUi.semilla),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.initial,
      onGenerateInitialRoutes: (name) => [
        AppRouter.onGenerateRoute(RouteSettings(name: name)),
      ],
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}