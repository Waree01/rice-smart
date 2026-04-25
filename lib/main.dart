import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logger/logger.dart';

import 'app.dart';
import 'config/env.dart';
import 'core/services/embedding_service.dart';
import 'features/chatbot/providers/chatbot_providers.dart';

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

  final container = ProviderContainer();
  _warmUpRagIndex(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const RiceSmartApp(),
    ),
  );
}

/// Fire-and-forget: build the RAG embedding index in the background so
/// Pasadee's first reply already has retrieval working.
///
/// Silent no-op if the HuggingFace key is missing — the chatbot still
/// answers, just without knowledge-base grounding.
Future<void> _warmUpRagIndex(ProviderContainer container) async {
  final logger = Logger();
  try {
    final rag = container.read(ragServiceProvider);
    final backend = container.read(embeddingBackendProvider);
    final apiKey = backend == EmbeddingBackend.wangchanberta
        ? Env.huggingFaceApiKey
        : Env.openaiApiKey;
    final ok = await rag.buildIndex(backend: backend, apiKey: apiKey);
    container.read(ragReadyProvider.notifier).state = ok;
  } catch (e, s) {
    logger.w('RAG warm-up failed', error: e, stackTrace: s);
  }
}
