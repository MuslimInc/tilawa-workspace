import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzakri/di_container.dart';
import 'package:muzakri/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDI();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      child: MaterialApp.router(
        title: 'Muzakri',
        theme: ThemeData(primarySwatch: Colors.blue),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
