// lib/services/event_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event.dart';

class EventService {
  static const _baseUrl = 'http://127.0.0.1:8000';

  /// Fetches events from the unified `/events/all` endpoint
  static Future<List<Event>> fetchAllEvents({
    required String city,
    required String date,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/events/all'
      '?city=${Uri.encodeComponent(city)}'
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load all events (${res.statusCode})');
    }
    final List data = json.decode(res.body);
    return data.map((j) => Event.fromJson(j)).toList();
  }

  /// Fetch only SeatGeek events
  static Future<List<Event>> fetchSeatGeekEvents({
    required String city,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/events/seatgeek'
      '?city=${Uri.encodeComponent(city)}'
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load SeatGeek events (${res.statusCode})');
    }
    final List data = json.decode(res.body);
    return data.map((j) => Event.fromJson(j)).toList();
  }

  /// Fetch only Eventbrite events.
static Future<List<Event>> fetchEventbriteEvents({
  required String city,
  String? date,
}) async {
  final params = <String>[
    'city=${Uri.encodeComponent(city)}',
    if (date != null && date.isNotEmpty) 'date=${Uri.encodeComponent(date)}',
  ].join('&');

  final uri = Uri.parse('$_baseUrl/events/eventbrite?$params');
  final res = await http.get(uri);
  if (res.statusCode != 200) {
    throw Exception('Failed to load Eventbrite events (${res.statusCode})');
  }
  final data = json.decode(res.body) as List;
  return data.map((j) => Event.fromJson(j)).toList();
}


  /// Fetch only Ticketmaster events
  static Future<List<Event>> fetchTicketmasterEvents({
    required String city,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/events/ticketmaster'
      '?city=${Uri.encodeComponent(city)}'
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load Ticketmaster events (${res.statusCode})');
    }
    final List data = json.decode(res.body);
    return data.map((j) => Event.fromJson(j)).toList();
  }
}
