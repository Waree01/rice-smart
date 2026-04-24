import 'dart:convert';

import 'package:flutter/services.dart';

/// Lightweight, read-only accessor for the on-device knowledge base.
///
/// All KB assets live in `assets/knowledge_base/*.json` and are loaded
/// lazily on first use. The loader caches the parsed maps for the
/// lifetime of the app.
class KnowledgeBase {
  KnowledgeBase._();
  static final KnowledgeBase instance = KnowledgeBase._();

  Map<String, dynamic>? _diseases;
  Map<String, dynamic>? _pests;
  Map<String, dynamic>? _stages;
  Map<String, dynamic>? _practices;

  Future<Map<String, dynamic>> _load(String path) async {
    final raw = await rootBundle.loadString(path);
    return json.decode(raw) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> diseases() async {
    _diseases ??= await _load('assets/knowledge_base/diseases.json');
    return (_diseases!['diseases'] as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> pests() async {
    _pests ??= await _load('assets/knowledge_base/pests.json');
    return (_pests!['pests'] as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> stages() async {
    _stages ??= await _load('assets/knowledge_base/growing_stages.json');
    return (_stages!['stages'] as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> practices() async {
    _practices ??= await _load('assets/knowledge_base/best_practices.json');
    return (_practices!['practices'] as List).cast<Map<String, dynamic>>();
  }

  /// Returns the raw disease entry for [id], or null if missing.
  Future<Map<String, dynamic>?> diseaseById(String id) async {
    final list = await diseases();
    for (final d in list) {
      if (d['id'] == id) return d;
    }
    return null;
  }

  /// Returns the raw pest entry for [id], or null if missing.
  Future<Map<String, dynamic>?> pestById(String id) async {
    final list = await pests();
    for (final p in list) {
      if (p['id'] == id) return p;
    }
    return null;
  }
}
