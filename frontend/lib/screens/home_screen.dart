import 'package:flutter/material.dart';
import '../widgets/location_input.dart';
import '../widgets/interest_picker.dart';
import '../widgets/event_card.dart';
import '../models/event.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String city = '';
  List<String> selectedInterests = [];
  List<Event> events = [];
  final List<String> _sortOptions = ['title', 'price-asc', 'price-desc'];
  String _sortBy = 'title';
  bool isLoading = false;
  String? error;
  DateTime? selectedDate;

void _onSearch() async {
  if (city.trim().isEmpty || selectedDate == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please enter a city or location.')),
    );
    return;
  }

  setState(() {
    isLoading = true;
    error = null;
    events = [];
  });

  try {
    final result = await ApiService.fetchEvents(
      city: city,
      interests: selectedInterests.isNotEmpty ? selectedInterests : ['music', 'concert', 'show', 'comedy'],
      minPrice: 0,
      maxPrice: 1500,
      radius: 100,
      sortBy: _sortBy,
      date: selectedDate,
    );
    setState(() {
      events = result;
    });
  } catch (e) {
    setState(() {
      error = 'Failed to load events: ${e.toString()}';
    });
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("WTD", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("WhatToDo", style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            LocationInput(onChanged: (value) => city = value),
            const SizedBox(height: 12),
            InterestPicker(
              onSelectionChanged: (interests) => selectedInterests = interests,
            ),
            
            // ----- Logic for Date picking UI -----
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDate == null
                      ? 'No date selected'
                      : 'Selected: ${selectedDate!.toLocal().toString().split(' ')[0]}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                ),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null && picked != selectedDate) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: const Text('Pick a Date'),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: DropdownButton<String>(
                value: _sortBy,
                underline: SizedBox(), // removes the default blue underline
                items: _sortOptions.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(
                    option == 'price-asc'
                      ? 'Price (Low → High)'
                      : option == 'price-desc'
                        ? 'Price (High → Low)'
                        : 'Title (A → Z)'
                  ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
              },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _onSearch,
              child: const Text("Find Events"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? Center(child: Text(error!))
                      : events.isEmpty
                          ? const Center(child: Text("No events found"))
                          : ListView.builder(
                              itemCount: events.length,
                              itemBuilder: (context, index) =>
                                  EventCard(event: events[index]),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
