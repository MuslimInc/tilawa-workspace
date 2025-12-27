import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/qibla/domain/entities/qibla_direction_entity.dart';
import 'package:tilawa/features/qibla/presentation/widgets/qibla_compass_widget.dart';

void main() {
  testWidgets('renders qibla compass widget', (tester) async {
    const direction = QiblaDirectionEntity(
      qibla: 100,
      direction: 45,
      offset: 55,
    );

    // Mock asset loading to avoid exceptions?
    // If assets exist, it works.
    // If not, we might need to handle it.
    // We'll hope they exist or use DefaultAssetBundle. Since we did before.

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(375, 812),
        builder: (_, __) => const MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.blue,
            body: Center(child: QiblaCompassWidget(direction: direction)),
          ),
        ),
      ),
    );

    expect(find.text('55°'), findsOneWidget);
    expect(find.text('To Qibla'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(2)); // Dial and Needle
  });
}
