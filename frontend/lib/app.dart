// lib/app.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/event_search_screen.dart';

/// WhatToDoApp: A fun, visually striking UI with a permanent light theme
class WhatToDoApp extends StatefulWidget {
  const WhatToDoApp({Key? key}) : super(key: key);

  @override
  _WhatToDoAppState createState() => _WhatToDoAppState();
}

class _WhatToDoAppState extends State<WhatToDoApp> {
  /// Show sort options sheet
  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const SortOptionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhatToDo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: Scaffold(
        // Fixed light background gradient
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.grey.shade100],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // Enhanced header now permanently dark mode
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'What',
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            TextSpan(
                              text: 'ToDo',
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple.shade200,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Vertical spacing
                  const SizedBox(height: 12),

                  // Main content: EventSearchScreen
                  const Expanded(
                    child: EventSearchScreen(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for sorting options
class SortOptionsSheet extends StatelessWidget {
  const SortOptionsSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final options = ['Date', 'Price', 'Location', 'Source'];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sort Events By',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...options.map((opt) => ListTile(
                  title: Text(opt, style: GoogleFonts.poppins()),
                  onTap: () {
                    // Integrate sort logic here
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// End of lib/app.dart
