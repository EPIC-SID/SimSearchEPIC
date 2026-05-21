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
        imageUrl: map['image_url'] as String?,
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

  Future<SearchResponse> library() async {
    final response = await http
        .get(Uri.parse('$baseUrl/library'))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 503) {
      throw ApiException(
        'Search index not ready. Run: python clear_db.py && python index.py',
      );
    }
    if (response.statusCode != 200) {
      throw ApiException('Failed to load indexed images (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rawResults = data['results'] as List<dynamic>? ?? [];
    final results = rawResults.map((item) {
      final map = item as Map<String, dynamic>;
      return SearchResult(
        path: map['path'] as String,
        score: (map['score'] as num?)?.toDouble() ?? 1.0,
        imageUrl: map['image_url'] as String?,
        name: map['name'] as String? ?? 'Asset',
      );
    }).toList();

    return SearchResponse(
      query: '',
      totalIndexed: data['total_indexed'] as int? ?? results.length,
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

  Future<IndexStatus> indexStatus() async {
    final response = await http
        .get(Uri.parse('$baseUrl/index/status'))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw ApiException('Failed to load index status (${response.statusCode})');
    }

    return IndexStatus.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<IndexStatus> rebuildIndex() async {
    final response = await http
        .post(Uri.parse('$baseUrl/index/rebuild'))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw ApiException('Failed to start index rebuild (${response.statusCode})');
    }

    return IndexStatus.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
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

class IndexStatus {
  final bool running;
  final String status;
  final String message;
  final int indexedCount;
  final String stage;
  final int processed;
  final int total;
  final double percent;
  final String? currentFile;

  const IndexStatus({
    required this.running,
    required this.status,
    required this.message,
    required this.indexedCount,
    required this.stage,
    required this.processed,
    required this.total,
    required this.percent,
    this.currentFile,
  });

  factory IndexStatus.fromJson(Map<String, dynamic> data) {
    return IndexStatus(
      running: data['running'] as bool? ?? false,
      status: data['status'] as String? ?? 'unknown',
      message: data['message'] as String? ?? '',
      indexedCount: data['indexed_count'] as int? ?? 0,
      stage: data['stage'] as String? ?? 'idle',
      processed: data['processed'] as int? ?? 0,
      total: data['total'] as int? ?? 0,
      percent: (data['percent'] as num?)?.toDouble() ?? 0.0,
      currentFile: data['current_file'] as String?,
    );
  }
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}
