import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    required this.onTap,
    required this.title,
    required this.color,
  });
  final VoidCallback? onTap;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.90,
      height: 40,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          // backgroundColor: Color(0xFF003038),
          backgroundColor: color.withValues(alpha: 0.1),
          elevation: 0.0,
          shadowColor: Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title.toString(),
              textAlign: TextAlign.right,
              style: TextStyle(
                // color: Color(0xFF00DBFF),
                color: color,
                fontSize: 15.0,
                fontWeight: FontWeight.normal,
              ),
            ),
            // Spacer(),
            const Icon(
              Icons.keyboard_arrow_left,
              size: 18.0,
              color: Color(0xFFE0E0E0),
            ),
          ],
        ),
      ),
    );
  }
}
