import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ordersync/main.dart';
import 'package:ordersync/data/datasources/local_storage_service.dart';
import 'package:ordersync/providers/connectivity_provider.dart';

void main() {
  testWidgets('OrderSync app renders main screen successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final localStorage = LocalStorageService();
    await localStorage.init();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(localStorage),
        ],
        child: const OrderSyncApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('OrderSync'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
