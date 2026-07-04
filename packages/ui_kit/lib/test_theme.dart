import 'package:flutter/material.dart';

void main() {
  var x = RefreshIndicator.adaptive(onRefresh: () async {}, child: Container());
}
