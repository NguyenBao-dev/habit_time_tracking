import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'country_fallback.dart';

/// A country from https://restcountries.com/ (Countries API v5).
class Country {
  const Country({required this.name, required this.code});

  /// Common name, e.g. "United States".
  final String name;

  /// ISO 3166-1 alpha-2 code, e.g. "US".
  final String code;

  /// Reads one v5 record, which looks like
  /// `{"names": {"common": "Canada"}, "codes": {"alpha_2": "CA"}}`.
  factory Country.fromJson(Map<String, dynamic> json) => Country(
    name: (json['names'] as Map<String, dynamic>)['common'] as String,
    code: ((json['codes'] as Map<String, dynamic>?)?['alpha_2']
    as String?) ??
        '',
  );
}

class CountryLoadException implements Exception {
  const CountryLoadException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Loads the country list from the REST Countries v5 API and caches it for
/// the lifetime of the app, so reopening the picker is instant.
///
/// The v1–v4 endpoints (including the old `/v3.1/all`) were shut down; v5
/// needs an API key. Create a free key at https://restcountries.com/sign-up
/// and pass it at build/run time so it isn't committed to source control:
///
///     flutter run --dart-define=RESTCOUNTRIES_API_KEY=your_key
///
/// Without a key, or if the request fails for any reason, [fetch] logs the
/// cause and returns the bundled offline list instead.
class CountryRepository {
  CountryRepository({http.Client? client}) : _client = client ?? http.Client();

  /// Shared instance so the cache survives across screens.
  static final CountryRepository shared = CountryRepository();

  /// Shown first when the search box is empty (as in the wireframe).
  static const List<String> popularCodes = ['US', 'CA', 'MX', 'GB', 'AU', 'DE'];

  static const String _apiKey =
  String.fromEnvironment('RESTCOUNTRIES_API_KEY');

  // Only the two fields the picker needs. Commas are written literally, as
  // the docs show them. The free plan caps `limit` at 100, so ~250 countries
  // arrive over three pages.
  static const String _baseUrl = 'https://api.restcountries.com/countries/v5';
  static const String _fields = 'names.common,codes.alpha_2';
  static const int _pageSize = 100;
  static const int _maxPages = 10; // safety stop

  final http.Client _client;
  List<Country>? _cache;
  bool _usedFallback = false;

  /// True when the last [fetch] couldn't load the live list and returned the
  /// bundled offline list instead.
  bool get usedFallback => _usedFallback;

  /// Never throws: on any failure the real error is logged with
  /// `debugPrint` and the bundled list is returned. The fallback isn't
  /// cached, so the next call tries the API again.
  Future<List<Country>> fetch({bool forceRefresh = false}) async {
    final cached = _cache;
    if (!forceRefresh && cached != null) {
      _usedFallback = false;
      return cached;
    }

    try {
      final countries = await _fetchAll();
      _usedFallback = false;
      return _cache = countries;
    } catch (e) {
      debugPrint('CountryRepository: using offline list because: $e');
      _usedFallback = true;
      return fallbackCountries;
    }
  }

  Future<List<Country>> _fetchAll() async {
    if (_apiKey.isEmpty) {
      throw const CountryLoadException(
        'No REST Countries API key. Run with '
            '--dart-define=RESTCOUNTRIES_API_KEY=<your key> '
            '(free key: https://restcountries.com/sign-up).',
      );
    }

    final countries = <Country>[];
    var offset = 0;

    for (var page = 0; page < _maxPages; page++) {
      final uri = Uri.parse(
        '$_baseUrl?response_fields=$_fields&limit=$_pageSize&offset=$offset',
      );

      final http.Response response;
      try {
        response = await _client.get(uri, headers: {
          'Authorization': 'Bearer $_apiKey',
          'Accept': 'application/json',
        }).timeout(const Duration(seconds: 15));
      } on TimeoutException {
        throw const CountryLoadException('The request timed out.');
      }

      final body = _decode(response);
      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw const CountryLoadException('Response had no "data" object.');
      }

      final objects = (data['objects'] as List<dynamic>? ?? const [])
          .map((e) => Country.fromJson(e as Map<String, dynamic>))
          .toList();
      countries.addAll(objects);

      final meta = data['meta'];
      final more = meta is Map && meta['more'] == true;
      if (!more || objects.isEmpty) break;
      offset += objects.length;
    }

    if (countries.isEmpty) {
      throw const CountryLoadException('The service returned no countries.');
    }
    countries
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return countries;
  }

  /// Decodes a v5 response and turns its `errors` array (or a non-200 status)
  /// into a [CountryLoadException] carrying the server's own message, e.g.
  /// a 401 for a bad key or a 403 when the origin isn't allowed.
  Map<String, dynamic> _decode(http.Response response) {
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw CountryLoadException(
        'Unreadable response (HTTP ${response.statusCode}).',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw CountryLoadException(
        'Unexpected response shape (HTTP ${response.statusCode}).',
      );
    }

    final errors = decoded['errors'];
    if (response.statusCode != 200 || (errors is List && errors.isNotEmpty)) {
      final message = (errors is List &&
          errors.isNotEmpty &&
          errors.first is Map &&
          (errors.first as Map)['message'] != null)
          ? (errors.first as Map)['message']
          : 'no message';
      throw CountryLoadException('HTTP ${response.statusCode}: $message');
    }
    return decoded;
  }
}