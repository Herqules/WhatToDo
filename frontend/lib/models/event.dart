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

  // ← existing “venue” fields
  final String? venueName;
  final String? venueAddress;
  final String? venueFullAddress;
  final String? venueType;

  // ← new “flip‑side” fields
  final String? category;
  final String? venuePhone;
  final String? acceptedPayment;
  final String? parkingDetail;

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

    // ← wire in your new fields here
    this.venueName,
    this.venueAddress,
    this.venueFullAddress,
    this.venueType,
    this.category,
    this.venuePhone,
    this.acceptedPayment,
    this.parkingDetail,
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

        // ← deserialize your new fields
        venueName: j['venue_name'] as String?,
        venueAddress: j['venue_address'] as String?,
        venueFullAddress: j['venue_full_address'] as String?,
        venueType: j['venue_type'] as String?,
        category: j['category'] as String?,
        venuePhone: j['venue_phone'] as String?,
        acceptedPayment: j['accepted_payment'] as String?,
        parkingDetail: j['parking_detail'] as String?,
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

        // ← serialize your new fields
        'venue_name': venueName,
        'venue_address': venueAddress,
        'venue_full_address': venueFullAddress,
        'venue_type': venueType,
        'category': category,
        'venue_phone': venuePhone,
        'accepted_payment': acceptedPayment,
        'parking_detail': parkingDetail,
      };
}
