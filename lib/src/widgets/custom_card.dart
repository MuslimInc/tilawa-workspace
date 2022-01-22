import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  const CustomCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 5,
      ),
      // height: 150,
      decoration: const BoxDecoration(
        color: Color(0xFF24262B),
        borderRadius: BorderRadius.all(Radius.circular(7.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18.0,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
