import 'package:flutter_test/flutter_test.dart';

import 'package:picur_monitor/app.dart';

void main() {
  testWidgets('muestra el dashboard de PICUR sin Firebase', (tester) async {
    await tester.pumpWidget(const PicurApp(firebaseReady: false));

    expect(find.text('PICUR'), findsOneWidget);
    expect(find.text('Monitoreo en tiempo real'), findsOneWidget);
    expect(find.text('Sin señal del sensor'), findsOneWidget);
  });
}
