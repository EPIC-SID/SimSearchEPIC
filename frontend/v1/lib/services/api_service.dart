import 'dart:convert';

import 'package:http/http.dart' as http;

import '../widgets.dart';

class ApiService {
  ApiService({this.baseUrl = 'http://127.0.0.1:8000'});

  final String baseUrl;

  Future<HealthStatus> health() async {
    final response = await http
        .get(Uri.parse('$baseUrl/health'))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw ApiException('Health check failed (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return HealthStatus(
      status: data['status'] as String? ?? 'unknown',
      indexedCount: data['indexed_count'] as int? ?? 0,
    );
  }

  Future<SearchResponse> search(String query) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/search'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'query': query}),
        )
        .timeout(const Duration(seconds: 120));

    if (response.statusCode == 503) {
      throw ApiException(
        'Search index not ready. Run: python clear_db.py && python index.py',
      );
    }
    if (response.statusCode != 200) {
      final body = response.body;
      throw ApiException('Search failed (${response.statusCode}): $body');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rawResults = data['results'] as List<dynamic>? ?? [];

    final results = rawResults.map((item) {
      final map = item as Map<String, dynamic>;
      return SearchResult(
        path: map['path'] as String,
        score: (map['score'] as num).toDouble(),
        name: map['name'] as String? ?? 'Asset',
      );
    }).toList();

    return SearchResponse(
      query: data['query'] as String? ?? query,
      totalIndexed: data['total_indexed'] as int? ?? 0,
      count: data['count'] as int? ?? results.length,
      results: results,
    );
  }
  Future<Map<String, dynamic>> getConfig() async {
    final response = await http
        .get(Uri.parse('$baseUrl/config'))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw ApiException('Failed to load config (${response.statusCode})');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> updateConfig({
    double? confidenceThreshold,
    List<String>? folderPaths,
  }) async {
    final body = <String, dynamic>{};
    if (confidenceThreshold != null) body['confidence_threshold'] = confidenceThreshold;
    if (folderPaths != null) body['folder_paths'] = folderPaths;

    final response = await http
        .put(
          Uri.parse('$baseUrl/config'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw ApiException('Failed to save config (${response.statusCode})');
    }
  }
}

class HealthStatus {
  final String status;
  final int indexedCount;

  const HealthStatus({required this.status, required this.indexedCount});

  bool get isReady => status == 'ok' && indexedCount > 0;
}

class SearchResponse {
  final String query;
  final int totalIndexed;
  final int count;
  final List<SearchResult> results;

  const SearchResponse({
    required this.query,
    required this.totalIndexed,
    required this.count,
    required this.results,
  });
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}
