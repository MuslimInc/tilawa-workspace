import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../shared/custom_page_route.dart';
import '../widgets/home.dart';
import 'splash_screen.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Widget result = SplashScreen();

  @override
  void initState() {
    super.initState();

    Timer(const Duration(milliseconds: 2000), () {
      Navigator.of(
        context,
      ).pushAndRemoveUntil(CustomPageRoute(child: Home()), (route) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return result;
  }
}
