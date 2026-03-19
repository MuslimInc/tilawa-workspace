import 'package:flutter/material.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key, required this.suraNumber});
  final int suraNumber;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    return Container(
      width: screenWidth,
      margin: const EdgeInsets.only(top: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image(
            image: const AssetImage('assets/mainframe.png', package: 'quran'),
            width: screenWidth * 0.90,
            fit: BoxFit.fill,
          ),
          Text(
            String.fromCharCode(0xF100 + suraNumber - 1),
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'QCF_BSML',
              package: 'quran',
              color: Colors.black,
              fontSize: screenWidth * 0.05,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
