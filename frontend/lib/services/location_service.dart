import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  static Future<List<String>> searchCities(String query) async {
    if (query.isEmpty) return [];

    final url = Uri.parse(
  'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5'
);
    final response = await http.get(url, headers: {
      'User-Agent': 'what-to-do-app/1.0' // required by Nominatim
    });

    if (response.statusCode != 200) return [];

    final data = json.decode(response.body);
    return List<String>.from(data.map((item) => item['display_name']));
  }
}

