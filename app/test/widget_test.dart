import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nut_manager_app/data/database.dart';
import 'package:nut_manager_app/main.dart';

void main() {
  testWidgets('shows the seeded shopping list and an empty basket', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(NutManagerApp(database: database));
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Panko Bread Crumbs'), findsOneWidget);
    expect(find.text('Nothing in the basket yet.'), findsOneWidget);
  });
}
