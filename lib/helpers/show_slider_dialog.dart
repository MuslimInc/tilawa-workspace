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
    builder: (_) => _VolumeSlider(
      title: title,
      divisions: divisions,
      min: min,
      max: max,
      value: value,
      onChanged: onChanged,
      valueSuffix: valueSuffix,
    ),
  );
}

class _VolumeSlider extends StatefulWidget {
  final String title;
  final int divisions;
  final double min;
  final double max;
  final String valueSuffix;
  final double value;
  final ValueChanged<double> onChanged;
  const _VolumeSlider({
    required this.title,
    required this.divisions,
    required this.min,
    required this.max,
    required this.valueSuffix,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<_VolumeSlider> {
  late double currentValue;

  @override
  void initState() {
    super.initState();
    currentValue = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title, textAlign: TextAlign.center),
      content: SizedBox(
        height: 100.0,
        child: Column(
          children: [
            Text(
              '${currentValue.toStringAsFixed(1)}${widget.valueSuffix}',
              style: const TextStyle(
                fontFamily: 'Fixed',
                fontWeight: FontWeight.bold,
                fontSize: 24.0,
              ),
            ),
            Slider(
              divisions: widget.divisions,
              min: widget.min,
              max: widget.max,
              value: currentValue,
              onChanged: (newValue) {
                setState(() {
                  currentValue = newValue;
                });
                widget.onChanged(newValue);
              },
            ),
          ],
        ),
      ),
    );
  }
}
