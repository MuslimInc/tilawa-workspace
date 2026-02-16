import 'package:flutter/material.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key, required this.suraNumber});
  final int suraNumber;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        margin: const .only(bottom: 52),
        padding: const .symmetric(horizontal: 9),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Image(
              image: AssetImage('assets/mainframe.png', package: 'quran'),
              height: 48,
              fit: BoxFit.fill,
            ),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: '$suraNumber',
                style: const TextStyle(
                  fontFamily: 'arsura',
                  package: 'quran',
                  color: Colors.black,
                  fontSize: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
