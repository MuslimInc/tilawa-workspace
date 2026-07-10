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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Align(widthFactor: 1.0, child: Text('OK'))),
              ],
            ),
          ),
        ),
      ),
    );
    final size = tester.getSize(find.byType(Row));
    print('Row with Flexible size: $size');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 560),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(child: Align(widthFactor: 1.0, child: Text('OK'))),
              ],
            ),
          ),
        ),
      ),
    );
    final size2 = tester.getSize(find.byType(Row));
    print('Row with Expanded size: $size2');
    
    final alignSize = tester.getSize(find.byType(Align));
    print('Align with Expanded size: $alignSize');
  });
}
