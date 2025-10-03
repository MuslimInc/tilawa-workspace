import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzakri/bloc/alphabet_scrollbar/alphabet_scrollbar_bloc.dart';
import 'package:muzakri/bloc/reciter_details/reciter_details_bloc.dart';
import 'package:muzakri/bloc/reciters/reciters_bloc.dart';
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
      child: MultiBlocProvider(
        providers: [
          BlocProvider<RecitersBloc>(
            create: (context) => getIt<RecitersBloc>(),
          ),
          BlocProvider<ReciterDetailsBloc>(
            create: (context) => getIt<ReciterDetailsBloc>(),
          ),
          BlocProvider<AlphabetScrollbarBloc>(
            create: (context) => getIt<AlphabetScrollbarBloc>(),
          ),
        ],
        child: MaterialApp.router(
          title: 'Muzakri',
          theme: ThemeData(primarySwatch: Colors.blue),
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
