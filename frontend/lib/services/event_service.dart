// lib/services/event_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event.dart';
import '../config.dart';

class EventService {
  /// Fetches events from the unified `/events/all` endpoint
  static Future<List<Event>> fetchAllEvents({
    required String city,
    required String date,
  }) async {
    // now using kApiBaseUrl from config.dart
    final uri = Uri.parse(
      '$kApiBaseUrl/events/all'
      '?city=${Uri.encodeComponent(city)}'
      '&date=${Uri.encodeComponent(date)}'
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
      '$kApiBaseUrl/events/seatgeek'
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

    final uri = Uri.parse(
      '$kApiBaseUrl/events/eventbrite?$params'
    );
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
      '$kApiBaseUrl/events/ticketmaster'
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
