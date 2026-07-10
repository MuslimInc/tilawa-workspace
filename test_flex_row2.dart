import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Flex min', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 560),
            child: TextButton(
              onPressed: () {},
              style: ButtonStyle(
                minimumSize: WidgetStateProperty.all(Size(0, 48)),
                maximumSize: WidgetStateProperty.all(Size(double.infinity, 48)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text('OK')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final size = tester.getSize(find.byType(TextButton));
    print('Button size: $size');
  });
}
