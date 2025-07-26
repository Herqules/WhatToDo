// lib/models/event.dart

class Event {
  final String title;
  final String description;
  final String location;
  final String price;
  final String date;          // YYYY-MM-DD
  final String startDate;     // localDate
  final String startTime;     // localTime
  final String startDatetime; // combined ISO
  final String ticketUrl;
  final String source;
  final double? latitude;
  final double? longitude;

  // ← new, nullable
  final String? venueName;
  final String? venueAddress;
  final String? venueFullAddress;
  final String? venueType;

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
    // ← new
    this.venueName,
    this.venueAddress,
    this.venueFullAddress,
    this.venueType,
  });

  factory Event.fromJson(Map<String, dynamic> j) => Event(
        title: j['title'] as String? ?? 'No Title',
        description: j['description'] as String? ?? '',
        location: j['location'] as String? ?? '',
        price: j['price'] as String? ?? '',
        date: j['date'] as String? ?? '',
        startDate: j['start_date'] as String? ?? '',
        startTime: j['start_time'] as String? ?? '',
        startDatetime: j['start_datetime'] as String? ?? '',
        ticketUrl: j['ticket_url'] as String? ?? '',
        source: j['source'] as String? ?? '',
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
        // ← wire up the new fields
        venueName: j['venue_name'] as String?,
        venueAddress: j['venue_address'] as String?,
        venueFullAddress: j['venue_full_address'] as String?,
        venueType: j['venue_type'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'location': location,
        'price': price,
        'date': date,
        'start_date': startDate,
        'start_time': startTime,
        'start_datetime': startDatetime,
        'ticket_url': ticketUrl,
        'source': source,
        'latitude': latitude,
        'longitude': longitude,
        // ← include new fields if you ever post back
        'venue_name': venueName,
        'venue_address': venueAddress,
        'venue_full_address': venueFullAddress,
        'venue_type': venueType,
      };
}
