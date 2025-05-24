// lib/services/event_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event.dart';

class EventService {
  // Point this to wherever your FastAPI is running:
  static const _baseUrl = 'http://127.0.0.1:8000';

  /// Fetches all events for [city] on [date].
  static Future<List<Event>> fetchEvents({
    required String city,
    //required String date, // 'YYYY-MM-DD'
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/events/all'
      '?city=${Uri.encodeComponent(city)}'
      //'&date=$date'
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load events (${res.statusCode})');
    }
    final List data = json.decode(res.body);
    return data.map((j) => Event.fromJson(j)).toList();
  }
}

