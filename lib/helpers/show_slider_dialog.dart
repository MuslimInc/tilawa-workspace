import 'package:flutter/material.dart';

void showSliderDialog({
  required BuildContext context,
  required String title,
  required int divisions,
  required double min,
  required double max,
  String valueSuffix = '',
  required double value,
  required ValueChanged<double> onChanged,
}) {
  showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        double currentValue = value;

        return AlertDialog(
          title: Text(title, textAlign: TextAlign.center),
          content: SizedBox(
            height: 100.0,
            child: Column(
              children: [
                Text(
                  '${currentValue.toStringAsFixed(1)}$valueSuffix',
                  style: const TextStyle(
                    fontFamily: 'Fixed',
                    fontWeight: FontWeight.bold,
                    fontSize: 24.0,
                  ),
                ),
                Slider(
                  divisions: divisions,
                  min: min,
                  max: max,
                  value: currentValue,
                  onChanged: (newValue) {
                    setState(() {
                      currentValue = newValue;
                    });
                    onChanged(newValue);
                  },
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
