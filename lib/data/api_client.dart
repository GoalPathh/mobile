import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:4000/api/v1',
);

class ApiException implements Exception {
  const ApiException(this.message, [this.statusCode = 0]);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client, FlutterSecureStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'goalpath_access_token';
  static const _refreshKey = 'goalpath_refresh_token';

  final http.Client _client;
  final FlutterSecureStorage _storage;

  Future<bool> hasSession() async =>
      (await _storage.read(key: _accessKey))?.isNotEmpty ?? false;

  Future<void> signIn(String email, String password) async {
    final data = await request(
      '/auth/login',
      method: 'POST',
      body: {'email': email, 'password': password},
      authenticated: false,
    );
    if (!await _saveSession(data)) {
      throw const ApiException('Sesi login tidak diterima dari server.');
    }
  }

  Future<bool> signUp(String name, String email, String password) async {
    final data = await request(
      '/auth/register',
      method: 'POST',
      body: {'name': name, 'email': email, 'password': password},
      authenticated: false,
    );
    return _saveSession(data);
  }

  Future<void> signOut() async {
    try {
      await request('/auth/logout', method: 'POST');
    } on Object {
      // Clear the local session even when the API is unreachable.
    } finally {
      await _clearSession();
    }
  }

  Future<dynamic> get(String path) => request(path);

  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    var response = await _send(
      path,
      method,
      body,
      authenticated: authenticated,
    );

    if (authenticated && response.statusCode == 401) {
      final refreshToken = await _storage.read(key: _refreshKey);
      if (refreshToken == null || refreshToken.isEmpty) {
        await _clearSession();
        throw const ApiException('Sesi berakhir. Silakan login kembali.', 401);
      }

      try {
        final refreshResponse = await _send('/auth/refresh', 'POST', {
          'refreshToken': refreshToken,
        }, authenticated: false);
        final refreshData = _readSuccess(refreshResponse);
        if (!await _saveSession(refreshData)) {
          throw const ApiException('Sesi tidak dapat diperbarui.', 401);
        }
        response = await _send(path, method, body, authenticated: true);
      } on Object {
        await _clearSession();
        rethrow;
      }
    }

    return _readSuccess(response);
  }

  Future<http.Response> _send(
    String path,
    String method,
    Map<String, dynamic>? body, {
    required bool authenticated,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (authenticated) {
      final token = await _storage.read(key: _accessKey);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    final base = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    final request = http.Request(method, Uri.parse('$base$path'))
      ..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    try {
      return await http.Response.fromStream(await _client.send(request));
    } on Exception {
      throw const ApiException(
        'Tidak dapat terhubung ke API. Periksa koneksi dan API_BASE_URL.',
      );
    }
  }

  dynamic _readSuccess(http.Response response) {
    if (response.statusCode == 204 || response.body.isEmpty) return null;

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw ApiException(
        'Respons server tidak dapat dibaca.',
        response.statusCode,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded is Map ? decoded['error'] : null;
      final message = error is Map ? error['message'] : null;
      throw ApiException(
        message is String
            ? message
            : 'Permintaan gagal (${response.statusCode}).',
        response.statusCode,
      );
    }

    return decoded is Map && decoded.containsKey('data')
        ? decoded['data']
        : decoded;
  }

  Future<bool> _saveSession(dynamic data) async {
    if (data is! Map) return false;
    final session = data['session'];
    if (session is! Map) return false;
    final accessToken = session['access_token'];
    final refreshToken = session['refresh_token'];
    if (accessToken is! String || refreshToken is! String) return false;
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
    return true;
  }

  Future<void> _clearSession() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
