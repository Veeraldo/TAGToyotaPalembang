import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tagtoyota/screen/profile_screen.dart';
import 'package:tagtoyota/screen/search_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late String greeting;

  Map<DateTime, List<String>> _events = {};
  Map<DateTime, List<Map<String, dynamic>>> _fullEvents = {};
  List<String> _selectedEvents = [];
  List<Map<String, dynamic>> _selectedFullEvents = [];

  @override
  void initState() {
    super.initState();
    _updateGreeting();
    _fetchEvents();
    Future.delayed(const Duration(seconds: 1), _showPopup);
  }

  /// === OPEN WHATSAPP ===
  Future<void> _openWhatsApp(String phone, String message) async {
    final text = Uri.encodeComponent(message);
    final uri = Uri.parse("https://wa.me/$phone?text=$text");

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Tidak dapat membuka WhatsApp');
    }
  }

  /// === GREETING ===
  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      greeting = "Selamat pagi";
    } else if (hour >= 12 && hour < 15) {
      greeting = "Selamat siang";
    } else if (hour >= 15 && hour < 18) {
      greeting = "Selamat sore";
    } else {
      greeting = "Selamat malam";
    }
  }

  /// === QUOTE API ===
  Future<String> fetchAPI() async {
    try {
      final response = await http.get(Uri.parse('https://zenquotes.io/api/random'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return "${data[0]['q']} — ${data[0]['a']}";
      } else {
        return "Tetap semangat menjalani harimu! 💪";
      }
    } catch (e) {
      return "Hari ini adalah kesempatan baru untuk jadi lebih baik.";
    }
  }

  /// === FETCH EVENTS ===
  Future<void> _fetchEvents() async {
    final snapshot = await FirebaseFirestore.instance.collection('customers').get();

    Map<DateTime, List<Map<String, dynamic>>> fetchedEvents = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();

      if (data.containsKey('Tanggal_Lahir')) {
        try {
          final parts = data['Tanggal_Lahir'].split('/');
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);

          final date = DateTime(year, month, day);

          fetchedEvents.putIfAbsent(date, () => []);
          fetchedEvents[date]!.add(data);
        } catch (e) {
          debugPrint("Error parsing date: ${data['Tanggal_Lahir']} | $e");
        }
      }
    }

    setState(() {
      _fullEvents = fetchedEvents;
      _events = fetchedEvents.map((key, value) => MapEntry(key, value.map((e) => e['Customer_Name'] as String).toList()));
    });
  }

  /// === POPUP ===
  Future<void> _showPopup() async {
    final user = FirebaseAuth.instance.currentUser;
    final username = user?.displayName ?? "User";
    final quote = await fetchAPI();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "$greeting, $username 👋",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          quote,
          style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  List<String> _getEventsForDay(DateTime day) {
    return _events.entries
        .where((entry) => entry.key.day == day.day && entry.key.month == day.month)
        .expand((entry) => entry.value)
        .toList();
  }

  List<Map<String, dynamic>> _getFullEventsForDay(DateTime day) {
    return _fullEvents.entries
        .where((entry) => entry.key.day == day.day && entry.key.month == day.month)
        .expand((entry) => entry.value)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final username = user?.displayName ?? "User";

    final List<IconData> _icons = [Icons.home, Icons.search, Icons.person];
    final List<String> _labels = ["Home", "Search", "Profile"];
    final List<Widget> _screens = [
      _buildHomeContent(username),
      const SearchScreen(),
      const ProfileScreen(),
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('id', 'ID'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: const Offset(0, 3))],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset("assets/TAGNyamping.png", height: 50, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(child: _screens[_currentIndex]),
        bottomNavigationBar: _buildBottomNav(_icons, _labels),
      ),
    );
  }

  /// === BOTTOM NAVIGATION ===
  Widget _buildBottomNav(List<IconData> icons, List<String> labels) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: const Offset(0, -3))],
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(icons.length, (index) {
            final isSelected = _currentIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _currentIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.red.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icons[index], color: isSelected ? Colors.red : Colors.grey, size: isSelected ? 28 : 24),
                    const SizedBox(height: 4),
                    if (isSelected)
                      Text(labels[index],
                          style: const TextStyle(
                              color: Color(0xFFFE0000),
                              fontWeight: FontWeight.bold,
                              fontSize: 12))
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  /// === HOME CONTENT ===
  Widget _buildHomeContent(String username) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("$greeting, $username",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black)),
            const SizedBox(height: 8),
            TableCalendar(
              locale: 'id_ID',
              firstDay: DateTime.utc(2000, 1, 1),
              lastDay: DateTime.utc(9999, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _selectedEvents = _getEventsForDay(selectedDay);
                  _selectedFullEvents = _getFullEventsForDay(selectedDay);
                });
              },
              eventLoader: _getEventsForDay,
              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                leftChevronIcon: Icon(Icons.chevron_left, color: Color.fromARGB(255, 240, 16, 0)),
                rightChevronIcon: Icon(Icons.chevron_right, color: Colors.red),
                titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(color: Color.fromARGB(255, 255, 17, 0), shape: BoxShape.circle),
                weekendTextStyle: TextStyle(color: Colors.red),
                defaultTextStyle: TextStyle(color: Colors.black),
              ),
              calendarBuilders: CalendarBuilders(
                dowBuilder: (context, day) {
                  if (day.weekday == DateTime.sunday) {
                    final text = DateFormat.E().format(day);
                    return Center(child: Text(text, style: const TextStyle(color: Colors.red)));
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedFullEvents.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _selectedFullEvents.map((event) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ExpansionTile(
                      leading: const Icon(Icons.event, color: Colors.red),
                      title: Text("${event['Customer_Name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.keyboard_arrow_down),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Model & Tanggal SPK
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.directions_car, size: 20, color: Colors.black54),
                                      const SizedBox(width: 6),
                                      Text("${event['Model']}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                  Text("${event['Tanggal_Spk_Do']}", style: const TextStyle(fontSize: 14, color: Colors.black54)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Tanggal Lahir
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 20, color: Colors.black54),
                                  const SizedBox(width: 6),
                                  Text("${event['Tanggal_Lahir']}", style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                              if (event.containsKey('Olahraga')) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.directions_run, size: 20, color: Colors.black54),
                                    const SizedBox(width: 6),
                                    Text("Olahraga: ${event['Olahraga']}", style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ],
                              if (event.containsKey('Makanan')) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.fastfood, size: 20, color: Colors.black54),
                                    const SizedBox(width: 6),
                                    Text("Makanan: ${event['Makanan']}", style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 8),
                              // Tombol Chat per event
                              Align(
  alignment: Alignment.centerRight,
  child: FloatingActionButton.small(
    backgroundColor: Colors.red,
    onPressed: () {
      final phone = event['No_HP'];

      final today = DateTime.now();
      final birthDateParts = event['Tanggal_Lahir'].split('/');
      final birthDay = int.parse(birthDateParts[0]);
      final birthMonth = int.parse(birthDateParts[1]);


      final nextBirthday = DateTime(today.year, birthMonth, birthDay);

      String message;

      if (nextBirthday.difference(today).inDays == 7) {
        // H-7
        message = "Hai ${event['Customer_Name']}, saya $username dari PT TAG Toyota Palembang ingin mengingatkan bahwa ${event['Customer_Name']} sebentar lagi Ulang Tahun nih! Kalau berkenan, silahkan mengisi form di bawah ini.";
      } else if (nextBirthday.day == today.day && nextBirthday.month == today.month) {
        // Hari ulang tahun
        message = "Hai ${event['Customer_Name']}, Selamat Ulang Tahun! 🎉 Semoga sehat dan sukses selalu!";
      } else {
        message = "Hai ${event['Customer_Name']}, saya $username dari PT TAG Toyota Palembang ingin mengingatkan tentang customer.";
      }

      _openWhatsApp(phone, message);
    },
    child: const Icon(Icons.chat, color: Colors.white, size: 20),
  ),
),

                            ],
                          ),
                        )
                      ],
                    ),
                  );
                }).toList(),
              )
            else
              const Text("Tidak ada Customer pada tanggal ini.",
                  style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}
