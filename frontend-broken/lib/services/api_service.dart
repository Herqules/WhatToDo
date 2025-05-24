import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/events/all'; // Replace with your IP if testing on real device

  static Future<List<Event>> fetchEvents({
    required String city,
    List<String>? interests,
    double minPrice = 0,
    double maxPrice = 1500,
    double radius = 100,
    String sortBy = 'title',
    DateTime? date,
  }) async {
    final interestQuery = (interests != null && interests.isNotEmpty)
        ? interests.join(" ")
        : "";

    final uri = Uri.parse(
  '$baseUrl?city=$city&interest=$interestQuery&min_price=$minPrice&max_price=$maxPrice&radius=$radius&sort_by=$sortBy');


    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Event.fromJson(json)).toList();
    } else {
      throw Exception("Failed to fetch events: ${response.statusCode}");
    }
  }
}
