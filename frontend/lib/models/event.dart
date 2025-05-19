class Event {
  final String title;
  final String description;
  final String location;
  final String price;
  final String ticketUrl;
  final String source;
  final String? latitude;
  final String? longitude;
  final String date;

  Event({
    required this.title,
    required this.description,
    required this.location,
    required this.price,
    required this.ticketUrl,
    required this.source,
    this.latitude,
    this.longitude,
    required this.date,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? '',
      location: json['location'] ?? 'Unknown',
      price: json['price'] ?? 'N/A',
      ticketUrl: json['ticket_url'] ?? '',
      source: json['source'] ?? '',
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      date: json['date'] ?? '',
    );
  }
}
