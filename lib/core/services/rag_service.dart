import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/knowledge_base.dart';
import 'embedding_service.dart';
import 'vector_store.dart';

/// Retrieval-Augmented Generation service.
///
/// Index: the Thai KB (diseases, pests, stages, practices) is flattened
/// into short passages, embedded, and cached on disk so subsequent app
/// launches avoid the HuggingFace cost.
///
/// At query time we embed the user's question, pull the top-k closest
/// passages, and return a formatted prompt suffix that the
/// [LlmGateway] can inject as additional system context.
class RagService {
  RagService({
    required EmbeddingService embedder,
    Logger? logger,
  })  : _embedder = embedder,
        _logger = logger ?? Logger();

  final EmbeddingService _embedder;
  final Logger _logger;
  final VectorStore _store = VectorStore();

  static const _cacheKeyPrefix = 'rag_index_v1_';

  EmbeddingBackend _lastBackend = EmbeddingBackend.wangchanberta;

  bool get isIndexed => !_store.isEmpty;
  int get indexSize => _store.length;
  EmbeddingBackend get activeBackend => _lastBackend;

  /// Build the in-memory index. Reuses a cached copy if the cached
  /// backend matches [backend]; otherwise re-embeds the whole corpus.
  Future<bool> buildIndex({
    required EmbeddingBackend backend,
    required String apiKey,
  }) async {
    _lastBackend = backend;
    if (apiKey.isEmpty) {
      _logger.w('RAG disabled: no API key for $backend');
      return false;
    }

    final cacheKey = '$_cacheKeyPrefix${backend.name}';
    final cached = await _loadCache(cacheKey);
    if (cached) {
      _logger.i('RAG index loaded from cache (${_store.length} docs)');
      return true;
    }

    final passages = await _buildPassages();
    _store.clear();
    for (final p in passages) {
      final embedding = await _embedder.embed(
        text: p.text,
        backend: backend,
        apiKey: apiKey,
      );
      if (embedding == null) {
        _logger.w('Skipping passage ${p.id} — embedding failed');
        continue;
      }
      _store.add(Document(
        id: p.id,
        text: p.text,
        category: p.category,
        metadata: p.metadata,
        embedding: embedding,
      ));
    }
    await _persistCache(cacheKey);
    _logger.i('RAG index built: ${_store.length} docs');
    return !_store.isEmpty;
  }

  /// Retrieve the top-[k] most relevant passages for [query] and wrap
  /// them into a Thai prompt suffix. Returns `null` if RAG isn't
  /// available so callers can degrade gracefully.
  Future<String?> buildPromptSuffix({
    required String query,
    required String apiKey,
    int k = 3,
  }) async {
    if (_store.isEmpty) return null;
    final queryEmb = await _embedder.embed(
      text: query,
      backend: _lastBackend,
      apiKey: apiKey,
    );
    if (queryEmb == null) return null;
    final hits = _store.search(queryEmb, k: k);
    if (hits.isEmpty) return null;
    final buf = StringBuffer()
      ..writeln('ข้อมูลอ้างอิงจากฐานความรู้ (เรียงตามความเกี่ยวข้อง):');
    for (var i = 0; i < hits.length; i++) {
      final h = hits[i];
      buf.writeln('[${i + 1}] ${h.document.text.trim()}');
    }
    buf.writeln(
        'ให้ใช้ข้อมูลอ้างอิงข้างต้นประกอบการตอบ และถ้าข้อมูลไม่ครอบคลุมให้บอกตรง ๆ ครับ');
    return buf.toString();
  }

  /// Flatten the KB into short, topic-focused passages for retrieval.
  Future<List<_Passage>> _buildPassages() async {
    final kb = KnowledgeBase.instance;
    final out = <_Passage>[];

    for (final d in await kb.diseases()) {
      final name = d['nameTh'];
      final symptoms = (d['symptoms'] as List?)?.join(' ') ?? '';
      final rec = d['recommendation'] ?? '';
      final tips = (d['preventiveTips'] as List?)?.join(' ') ?? '';
      out.add(_Passage(
        id: 'disease_${d['id']}',
        category: 'disease',
        text: 'โรค$name: $symptoms คำแนะนำ: $rec การป้องกัน: $tips',
        metadata: {'source': 'disease', 'id': d['id']},
      ));
    }

    for (final p in await kb.pests()) {
      final name = p['nameTh'];
      final dmg = p['damage'] ?? '';
      final rec = p['recommendation'] ?? '';
      out.add(_Passage(
        id: 'pest_${p['id']}',
        category: 'pest',
        text: 'ศัตรูพืช$name: $dmg คำแนะนำ: $rec',
        metadata: {'source': 'pest', 'id': p['id']},
      ));
    }

    for (final s in await kb.stages()) {
      final name = s['nameTh'];
      final actions = (s['key_actions'] as List?)?.join(' ') ?? '';
      final alerts = (s['alerts'] as List?)?.join(' ') ?? '';
      out.add(_Passage(
        id: 'stage_${s['id']}',
        category: 'stage',
        text: 'ระยะ$name: $actions ข้อควรระวัง: $alerts',
        metadata: {'source': 'stage', 'id': s['id']},
      ));
    }

    for (final b in await kb.practices()) {
      out.add(_Passage(
        id: 'practice_${b['id']}',
        category: 'practice',
        text: '${b['title']}: ${b['body']}',
        metadata: {'source': 'practice', 'id': b['id']},
      ));
    }

    return out;
  }

  Future<bool> _loadCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return false;
      final decoded = json.decode(raw) as List<dynamic>;
      _store.loadJson(decoded);
      return !_store.isEmpty;
    } catch (e) {
      _logger.w('RAG cache load failed', error: e);
      return false;
    }
  }

  Future<void> _persistCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, json.encode(_store.toJson()));
    } catch (e) {
      _logger.w('RAG cache persist failed', error: e);
    }
  }
}

class _Passage {
  final String id;
  final String category;
  final String text;
  final Map<String, dynamic> metadata;
  const _Passage({
    required this.id,
    required this.category,
    required this.text,
    required this.metadata,
  });
}
