// Basic smoke test — verifies the app boots and renders the splash screen
// without throwing.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:crumbio_mobile_app/core/constants/hive_table_constants.dart';
import 'package:crumbio_mobile_app/core/services/storage/user_session_service.dart';
import 'package:crumbio_mobile_app/features/marketplace/data/models/product/product_hive_model.dart';
import 'package:crumbio_mobile_app/main.dart';

import 'helpers/test_fakes.dart';

void main() {
  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('crumbio_hive_test');
    Hive.init(dir.path);
    Hive.registerAdapter(ProductHiveModelAdapter());
    await Hive.openBox<ProductHiveModel>(HiveTableConstant.productTable);
    await Hive.openBox(HiveTableConstant.sessionTable);
  });

  testWidgets('CrumbioApp builds and shows the splash screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userSessionServiceProvider.overrideWithValue(FakeUserSessionService()),
        ],
        child: const CrumbioApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Crumbio'), findsOneWidget);

    // The splash screen holds itself up for a minimum 2s via
    // Future.delayed before navigating onward — flush that timer so the
    // test doesn't end with it still pending.
    await tester.pump(const Duration(seconds: 3));
  });
}
