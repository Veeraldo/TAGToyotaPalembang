import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class SearchScreen extends StatefulWidget {
  final Map<String, String> customMessages; // Ambil dari HomeScreen

  const SearchScreen({super.key, required this.customMessages});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  String _filter = "nama"; // default filter
  late Map<String, String> _customMessages;

  @override
  void initState() {
    super.initState();
    _customMessages = widget.customMessages;

    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase();
      });
    });
  }

  Stream<QuerySnapshot> _getCustomerStream() {
    return FirebaseFirestore.instance.collection('customers').snapshots();
  }

  void _openWhatsApp(String phone, String message) async {
    final text = Uri.encodeComponent(message);
    final uri = Uri.parse("https://wa.me/$phone?text=$text");
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _editMessage(String name, String oldMessage) async {
    final controller = TextEditingController(text: oldMessage);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Pesan untuk $name"),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Edit pesan...",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _customMessages[name] = controller.text.trim();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Pesan berhasil disimpan!"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  String _generateMessage(String name, String tanggalLahir) {
    final today = DateTime.now();
    final user = FirebaseAuth.instance.currentUser;
    final username = user?.displayName ?? "User";

    if (_customMessages.containsKey(name)) {
      return _customMessages[name]!;
    }

    try {
      final parts = tanggalLahir.split('/');
      final birthDay = int.parse(parts[0]);
      final birthMonth = int.parse(parts[1]);
      final nextBirthday = DateTime(today.year, birthMonth, birthDay);

      final birthday = nextBirthday.isBefore(today)
          ? DateTime(today.year + 1, birthMonth, birthDay)
          : nextBirthday;

      final diffDays = birthday.difference(today).inDays;

      if (diffDays == 6) {
        return "Hai $name, saya $username ingin mengingatkan bahwa kamu sebentar lagi ulang tahun!";
      } else if (diffDays == 2) {
        return "Hai $name, saya $username dari PT TAG Toyota Palembang ingin mengingatkan bahwa kamu sebentar lagi ulang tahun!";
      } else if (birthday.day == today.day && birthday.month == today.month) {
        return "Hai $name, Selamat Ulang Tahun! 🎉 Semoga sehat dan sukses selalu!";
      } else {
        return "Hai $name, saya $username ingin menyapa pelanggan terbaik kami.";
      }
    } catch (_) {
      return "Hai $name, semoga harimu menyenangkan!";
    }
  }

  Widget _buildCustomerCard(Map<String, dynamic> data) {
    final name = data['Customer_Name'] ?? '-';
    final phone = data['No_HP'] ?? '-';
    final tanggalLahir = data['Tanggal_Lahir'] ?? '-';
    final message = _generateMessage(name, tanggalLahir);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ExpansionTile(
        leading: const Icon(Icons.event, color: Colors.red),
        title: Text(name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        trailing: const Icon(Icons.keyboard_arrow_down),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_car,
                            size: 20, color: Colors.black54),
                        const SizedBox(width: 6),
                        Text("${data['Model'] ?? '-'}",
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    Text("${data['Tanggal_Spk_Do'] ?? '-'}",
                        style:
                            const TextStyle(fontSize: 14, color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.cake, size: 20, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(tanggalLahir, style: const TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.grey),
                      onPressed: () => _editMessage(name, message),
                    ),
                    IconButton(
                      icon: const Icon(FontAwesomeIcons.whatsapp,
                          color: Colors.green),
                      onPressed: () => _openWhatsApp(phone, message),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthNow = DateFormat('MMMM', 'id_ID').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 🔍 Search bar tetap aktif tanpa rebuild
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari berdasarkan $_filter...',
                        prefixIcon: const Icon(Icons.search, color: Colors.red),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.filter_list, color: Colors.red),
                    onSelected: (val) {
                      setState(() => _filter = val);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: "nama", child: Text("Nama")),
                      PopupMenuItem(
                          value: "no_rangka", child: Text("Nomor Rangka")),
                      PopupMenuItem(value: "model", child: Text("Model")),
                    ],
                  ),
                ],
              ),
            ),

            // 🔽 Daftar hasil pencarian & nearest date
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getCustomerStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("Tidak ada data pelanggan."));
                  }

                  final allDocs = snapshot.data!.docs
                      .map((e) => e.data() as Map<String, dynamic>)
                      .toList();

                  final searchResults = _searchText.isEmpty
                      ? []
                      : allDocs.where((data) {
                          final name =
                              (data['Customer_Name'] ?? '').toString().toLowerCase();
                          final model =
                              (data['Model'] ?? '').toString().toLowerCase();
                          final noRangka =
                              (data['No_Rangka'] ?? '').toString().toLowerCase();

                          if (_filter == "nama") return name.contains(_searchText);
                          if (_filter == "model") return model.contains(_searchText);
                          return noRangka.contains(_searchText);
                        }).toList();

                  final nearestMonth = DateTime.now().month;
                  final nearestList = allDocs.where((data) {
                    try {
                      final parts = data['Tanggal_Lahir'].split('/');
                      final month = int.parse(parts[1]);
                      return month == nearestMonth;
                    } catch (_) {
                      return false;
                    }
                  }).toList();

                  return ListView(
                    padding: const EdgeInsets.only(bottom: 12),
                    children: [
                      if (_searchText.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Text("Hasil Pencarian",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        if (searchResults.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: Text("Tidak ada hasil ditemukan.")),
                          )
                        else
                          ...searchResults.map((data) => _buildCustomerCard(data)).toList(),
                      ],
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Text("Nearest Date $monthNow",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      ...nearestList.map(_buildCustomerCard),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
