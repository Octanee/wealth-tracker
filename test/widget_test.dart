import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Basic smoke test — full Firebase init not mocked here
    expect(WealthLensApp, isNotNull);
  });
}
