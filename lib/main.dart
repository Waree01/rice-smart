import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Runtime setup — keep this list small and forgiving. Anything that
  // requires a network or a user-provided key is initialized lazily
  // in its own Riverpod provider so a missing key never blocks boot.
  await Env.load();
  await Hive.initFlutter();
  await initializeDateFormatting('th', null);

  // Firebase is deliberately left uninitialized until a real
  // google-services.json / GoogleService-Info.plist is provisioned.
  // Uncomment once configured:
  //
  //   await Firebase.initializeApp(
  //       options: DefaultFirebaseOptions.currentPlatform);
  //   await NotificationService.instance.initialize();

  runApp(
    const ProviderScope(child: RiceSmartApp()),
  );
}
