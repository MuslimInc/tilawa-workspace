import 'package:flutter/material.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key, required this.suraNumber, this.fontSize});
  final int suraNumber;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: const BoxDecoration(),
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Image(
              image: AssetImage('assets/mainframe.png', package: 'quran'),
            ),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: '$suraNumber',
                style: TextStyle(
                  fontFamily: 'arsura',
                  package: 'quran',
                  color: Colors.black,
                  fontSize: fontSize ?? 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
