import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../screens/smart_khatma_hub_screen.dart';
import '../../smart_khatma_dependencies.dart';

/// Composition root for the Smart Khatma hub route.
class SmartKhatmaHubScope extends StatelessWidget {
  const SmartKhatmaHubScope({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SmartKhatmaDependencies.bloc(),
      child: const SmartKhatmaHubScreen(),
    );
  }
}
