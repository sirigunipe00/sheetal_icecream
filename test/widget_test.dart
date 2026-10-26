import 'package:sheetal_icecream/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('splash screen opens home without a track-order tab', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SheetalApp(showSplash: true));
    expect(find.text('100% PURE MILK ICE CREAM'), findsOneWidget);

    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.text('10 minutes'), findsOneWidget);
    expect(find.text('Track order'), findsNothing);
    expect(find.text('Butterscotch Waffle Cone'), findsNothing);
    expect(find.byKey(const Key('search-field')), findsOneWidget);
  });

  testWidgets('profile button opens the account sheet', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SheetalApp(showSplash: false));
    await tester.pump();
    expect(find.byKey(const Key('profile-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile-button')));
    await tester.pumpAndSettle();

    expect(find.text('Guest User'), findsOneWidget);
    expect(find.text('Your Orders'), findsOneWidget);
    expect(find.text('Track order'), findsNothing);
  });

  testWidgets('bottom navigation matches the prototype tabs', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SheetalApp(showSplash: false));
    await tester.pump();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Wishlist'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Track order'), findsNothing);
  });
}
