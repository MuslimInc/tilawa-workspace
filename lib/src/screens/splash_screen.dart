import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/images/mozakericon.svg'),
            const SizedBox(width: 10.0),
            const Text(
              'مذكري',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 40.0, color: Color(0xFFFEDF99)),
            ),
          ],
        ),
      ),
    );
  }
}
