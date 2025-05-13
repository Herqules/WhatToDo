import 'package:flutter/material.dart';

class InterestPicker extends StatefulWidget {
  final Function(List<String>) onSelectionChanged;

  const InterestPicker({required this.onSelectionChanged});

  @override
  _InterestPickerState createState() => _InterestPickerState();
}

class _InterestPickerState extends State<InterestPicker> {
  final List<String> _allInterests = [
    "Comedy",
    "Rap",
    "Pop",
    "Country",
    "Disco",
    "Jazz",
    "Theatre",
    "Concerts",
    "Music",
    "Shows",
    "Sports - National",
    "Sports - Local",
  ];

  final List<String> _selectedInterests = [];

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
    widget.onSelectionChanged(_selectedInterests);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      children: _allInterests.map((interest) {
        final isSelected = _selectedInterests.contains(interest);
        return FilterChip(
          label: Text(interest),
          selected: isSelected,
          onSelected: (_) => _toggleInterest(interest),
          selectedColor: Colors.deepPurple.shade100,
        );
      }).toList(),
    );
  }
}
