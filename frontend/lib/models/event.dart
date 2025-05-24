// lib/models/event.dart

class Event {
  final String title;
  final String description;
  final String location;
  final String price;
  final String date;            // yyyy-MM-dd or full ISO
  final String startDate;       // localDate
  final String startTime;       // localTime
  final String startDatetime;   // combined
  final String ticketUrl;
  final String source;
  final double? latitude;
  final double? longitude;

  Event({
    required this.title,
    required this.description,
    required this.location,
    required this.price,
    required this.date,
    required this.startDate,
    required this.startTime,
    required this.startDatetime,
    required this.ticketUrl,
    required this.source,
    this.latitude,
    this.longitude,
  });

  factory Event.fromJson(Map<String, dynamic> j) => Event(
    title: j['title'] ?? 'No Title',
    description: j['description'] ?? '',
    location: j['location'] ?? '',
    price: j['price'] ?? '',
    date: j['date'] ?? '',
    startDate: j['start_date'] ?? '',
    startTime: j['start_time'] ?? '',
    startDatetime: j['start_datetime'] ?? '',
    ticketUrl: j['ticket_url'] ?? '',
    source: j['source'] ?? '',
    latitude: j['latitude'] != null ? double.tryParse(j['latitude'].toString()) : null,
    longitude: j['longitude'] != null ? double.tryParse(j['longitude'].toString()) : null,
  );
}

