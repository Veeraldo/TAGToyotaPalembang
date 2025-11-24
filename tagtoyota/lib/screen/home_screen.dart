import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tagtoyota/helper/googleform_helper.dart';
import 'package:tagtoyota/screen/profile_screen.dart';
import 'package:tagtoyota/screen/search_screen.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:tagtoyota/helpers/google_form_helper.dart';

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

  final Map<String, String> _customMessages = {};
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _updateGreeting();
    Future.delayed(const Duration(seconds: 1), _showPopup);
  }

  Future<void> _openWhatsApp(String phone, String message) async {
    final text = Uri.encodeComponent(message);
    final uri = Uri.parse("https://wa.me/$phone?text=$text");

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Tidak dapat membuka WhatsApp');
    }
  }

  /// Kirim pesan dengan form Google yang sudah di-prefill ke WhatsApp
  Future<void> _sendWhatsAppWithForm(
    String customerName,
    String customerId,
    String phone,
    String baseMessage,
  ) async {
    try {
      print('DEBUG - _sendWhatsAppWithForm called');
      print('DEBUG - Customer: $customerName, ID: $customerId, Phone: $phone');

      final formUrl = GoogleFormHelper.generateFormUrl(
        customerId,
        customerName,
      );
      print('DEBUG - Form URL: $formUrl');

      // Gabungkan pesan dengan link form
      final message = '''$baseMessage

Silakan isi form berikut untuk melanjutkan:
$formUrl

ID dan Nama Anda sudah terisi otomatis di form.

Terima kasih!''';

      print('DEBUG - Full Message: $message');

      await _openWhatsApp(phone, message);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diarahkan ke WhatsApp'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('DEBUG - Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _editMessage(
    String customerName,
    String phone,
    String initialMessage,
    String customerId, {
    bool includeForm = false,
  }) async {
    final TextEditingController controller = TextEditingController(
      text: initialMessage,
    );

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Kirim Pesan untuk $customerName"),
            content: TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Edit pesan sebelum dikirim...",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Batal",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  final msg = controller.text.trim();
                  Navigator.pop(context);

                  final fullMsg =
                      includeForm
                          ? msg +
                              "\n\nSilakan isi form berikut untuk melanjutkan:\n" +
                              GoogleFormHelper.generateFormUrl(
                                customerId,
                                customerName,
                              ) +
                              "\n\nID dan Nama Anda sudah terisi otomatis di form.\n\nTerima kasih!"
                          : msg;

                  _openWhatsApp(phone, fullMsg);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Pesan dikirim ke WhatsApp"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text("Kirim"),
              ),
            ],
          ),
    );
  }

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

  Future<String> fetchAPI() async {
    try {
      final response = await http.get(
        Uri.parse('https://zenquotes.io/api/random'),
      );
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

  Future<void> _showPopup() async {
    final user = FirebaseAuth.instance.currentUser;
    final username = user?.displayName ?? "User";
    final quote = await fetchAPI();

    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white.withOpacity(0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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

  Widget _buildBottomNav(List<IconData> icons, List<String> labels) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? Colors.red.withOpacity(0.1)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icons[index],
                      color: isSelected ? Colors.red : Colors.grey,
                      size: isSelected ? 28 : 24,
                    ),
                    const SizedBox(height: 4),
                    if (isSelected)
                      Text(
                        labels[index],
                        style: const TextStyle(
                          color: Color(0xFFFE0000),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final username = user?.displayName ?? "User";

    final List<IconData> _icons = [Icons.home, Icons.search, Icons.person];
    final List<String> _labels = ["Home", "Search", "Profile"];
    final List<Widget> _screens = [
      _buildHomeContent(username),
      const SearchScreen(customMessages: {}),
      const ProfileScreen(),
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('en', 'US'), Locale('id', 'ID')],
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(
                    "assets/TAGNyamping.png",
                    height: 50,
                    fit: BoxFit.contain,
                  ),
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

  Widget _buildHomeContent(String username) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('customers').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Tidak ada data pelanggan."));
        }

        final docs = snapshot.data!.docs;
        Map<DateTime, List<Map<String, dynamic>>> fullEvents = {};
        for (var doc in docs) {
          final data = Map<String, dynamic>.from(
            doc.data() as Map<String, dynamic>,
          );

          data['real_doc_id'] = doc.id;
          if (data.containsKey('Tanggal_Lahir')) {
            try {
              final parts = data['Tanggal_Lahir'].split('/');
              final day = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              final year = int.parse(parts[2]);
              final date = DateTime(year, month, day);
              fullEvents.putIfAbsent(date, () => []);
              fullEvents[date]!.add(data);
            } catch (_) {}
          }
        }

        List<Map<String, dynamic>> selectedEvents = [];
        if (_selectedDay != null) {
          selectedEvents =
              fullEvents.entries
                  .where(
                    (entry) =>
                        entry.key.day == _selectedDay!.day &&
                        entry.key.month == _selectedDay!.month,
                  )
                  .expand((entry) => entry.value)
                  .toList();
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  "$greeting, $username",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
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
                    });
                  },
                  eventLoader: (day) {
                    return fullEvents.entries
                        .where(
                          (entry) =>
                              entry.key.day == day.day &&
                              entry.key.month == day.month,
                        )
                        .expand(
                          (entry) =>
                              entry.value.map((e) => e['Customer_Name'] ?? ''),
                        )
                        .toList();
                  },
                  headerStyle: const HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: Colors.red,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: Colors.red,
                    ),
                    titleTextStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  calendarStyle: const CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    weekendTextStyle: TextStyle(color: Colors.red),
                    defaultTextStyle: TextStyle(color: Colors.black),
                  ),
                ),
                const SizedBox(height: 16),
                if (selectedEvents.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        selectedEvents.map((event) {
                          final phone = event['No_HP'] ?? '';
                          final customerId =
                              event['real_doc_id'] ?? event['ID'] ?? 'N/A';
                          final today = DateTime.now();
                          final parts = event['Tanggal_Lahir'].split('/');
                          final birthDay = int.parse(parts[0]);
                          final birthMonth = int.parse(parts[1]);
                          final nextBirthday = DateTime(
                            today.year,
                            birthMonth,
                            birthDay,
                          );

                          String message;
                          if (_customMessages.containsKey(
                            event['Customer_Name'],
                          )) {
                            message = _customMessages[event['Customer_Name']]!;
                          } else if (nextBirthday.difference(today).inDays ==
                              6) {
                            message =
                                "Hai ${event['Customer_Name']}, saya $username dari PT TAG Toyota Palembang ingin mengingatkan bahwa kamu sebentar lagi ulang tahun!";
                          } else if (nextBirthday.difference(today).inDays ==
                              2) {
                            message =
                                "Hai ${event['Customer_Name']}, saya $username dari PT TAG Toyota Palembang ingin mengingatkan bahwa 3 hari lagi kamu ulang tahun!";
                          } else if (nextBirthday.day == today.day &&
                              nextBirthday.month == today.month) {
                            message =
                                "Hai ${event['Customer_Name']}, Selamat Ulang Tahun! 🎉 Semoga sehat dan sukses selalu!";
                          } else {
                            message =
                                "Hai ${event['Customer_Name']}, saya $username dari PT TAG Toyota Palembang ingin menyapa pelanggan terbaik kami.";
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ExpansionTile(
                              leading: const Icon(
                                Icons.event,
                                color: Colors.red,
                              ),
                              title: Text(
                                "${event['Customer_Name']}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: const Icon(Icons.keyboard_arrow_down),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.directions_car,
                                                size: 20,
                                                color: Colors.black54,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                "${event['Model'] ?? '-'}",
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            "${event['Tanggal_Spk_Do'] ?? '-'}",
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.cake,
                                            size: 20,
                                            color: Colors.black54,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            "${event['Tanggal_Lahir'] ?? '-'}",
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if ((event['Hobby'] ?? '')
                                          .toString()
                                          .trim()
                                          .isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.sports_esports,
                                                size: 20,
                                                color: Colors.black54,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                "${event['Hobby']}",
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if ((event['Makanan_Favorit'] ?? '')
                                          .toString()
                                          .trim()
                                          .isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.fastfood,
                                                size: 20,
                                                color: Colors.black54,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                "${event['Makanan_Favorit']}",
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          FloatingActionButton.small(
                                            heroTag: null,
                                            backgroundColor:
                                                Colors.grey.shade700,
                                            tooltip: 'Edit Pesan',
                                            onPressed: () {
                                              final includeForm =
                                                  nextBirthday
                                                      .difference(today)
                                                      .inDays ==
                                                  6;
                                              _editMessage(
                                                event['Customer_Name'],
                                                phone,
                                                message,
                                                customerId,
                                                includeForm: includeForm,
                                              );
                                            },
                                            child: const Icon(
                                              Icons.edit,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          if (nextBirthday
                                                  .difference(today)
                                                  .inDays ==
                                              6)
                                            FloatingActionButton.small(
                                              heroTag: null,
                                              backgroundColor: Colors.red,
                                              tooltip:
                                                  'Kirim ke WhatsApp dengan Form',
                                              onPressed: () {
                                                _sendWhatsAppWithForm(
                                                  event['Customer_Name'],
                                                  customerId,
                                                  phone,
                                                  message,
                                                );
                                              },
                                              child: const Icon(
                                                FontAwesomeIcons.whatsapp,
                                                color: Colors.white,
                                                size: 22,
                                              ),
                                            ),
                                          if (nextBirthday
                                                  .difference(today)
                                                  .inDays !=
                                              6)
                                            FloatingActionButton.small(
                                              heroTag: null,
                                              backgroundColor: const Color.fromARGB(255, 255, 17, 0),
                                              tooltip:
                                                  'Kirim Pesan ke WhatsApp',
                                              onPressed: () {
                                                _openWhatsApp(phone, message);
                                              },
                                              child: const Icon(
                                                FontAwesomeIcons.whatsapp,
                                                color: Colors.white,
                                                size: 22,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  )
                else
                  const Text(
                    "Tidak ada Customer pada tanggal ini.",
                    style: TextStyle(
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
