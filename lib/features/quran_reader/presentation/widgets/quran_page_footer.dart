import 'package:flutter/material.dart';

class QuranPageFooter extends StatelessWidget {
  const QuranPageFooter({
    super.key,
    required this.hizbNumber,
    required this.pageNumber,
  });

  final int hizbNumber;
  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 24, top: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8DAC0), // Darker beige for tag
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFC7B299)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hizb $hizbNumber',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade800,
                ),
              ),
              Container(
                height: 16,
                width: 1,
                color: Colors.brown.shade800,
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),
              Text(
                '$pageNumber',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
