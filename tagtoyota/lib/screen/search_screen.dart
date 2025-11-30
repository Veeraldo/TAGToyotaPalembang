import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:tagtoyota/helper/googleform_helper.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:tagtoyota/helpers/google_form_helper.dart';

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

  Future<void> _openWhatsApp(String phone, String message) async {
    final text = Uri.encodeComponent(message);
    final uri = Uri.parse("https://wa.me/$phone?text=$text");
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Kirim pesan dengan form Google yang sudah di-prefill ke WhatsApp
  Future<void> _sendWhatsAppWithForm(
    String customerName,
    String customerId,
    String phone,
    String baseMessage,
  ) async {
    try {
      final formUrl = GoogleFormHelper.generateFormUrl(
        customerId,
        customerName,
      );

      // Gabungkan pesan dengan link form
      final message = '''$baseMessage

Silakan isi form berikut untuk melanjutkan:
$formUrl

ID dan Nama Anda sudah terisi otomatis di form.

Terima kasih!''';

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _editMessage(
    String name,
    String phone,
    String oldMessage,
    dynamic tanggalLahir,
  ) async {
    final controller = TextEditingController(text: oldMessage);

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Kirim Pesan untuk $name"),
            content: TextField(
              controller: controller,
              maxLines: 4,
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
                  final includeForm = _getDaysUntilBirthday(tanggalLahir) == 6;
                  final fullMsg =
                      includeForm
                          ? msg +
                              "\n\nSilakan isi form berikut untuk melanjutkan:\n" +
                              GoogleFormHelper.generateFormUrl(name, name) +
                              "\n\nID dan Nama Anda sudah terisi otomatis di form.\n\nTerima kasih!"
                          : msg;
                  _openWhatsApp(phone, fullMsg);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Pesan dikirim ke WhatsApp"),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text("Kirim"),
              ),
            ],
          ),
    );
  }

  DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      for (final fmt in [
        DateFormat('MM/dd/yyyy'),
        DateFormat('dd/MM/yyyy'),
        DateFormat('M/d/yyyy'),
        DateFormat('d/M/yyyy'),
        DateFormat('yyyy-MM-dd'),
      ]) {
        try {
          return fmt.parse(value);
        } catch (_) {}
      }
    }
    return null;
  }

  String _generateMessage(String name, dynamic tanggalLahir) {
    final today = DateTime.now();
    final user = FirebaseAuth.instance.currentUser;
    final username = user?.displayName ?? "User";

    if (_customMessages.containsKey(name)) {
      return _customMessages[name]!;
    }

    try {
      final dob = _toDate(tanggalLahir);
      if (dob == null) throw 'no dob';
      final birthDay = dob.day;
      final birthMonth = dob.month;
      final nextBirthday = DateTime(today.year, birthMonth, birthDay);

      final birthday =
          nextBirthday.isBefore(today)
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

  int _getDaysUntilBirthday(dynamic tanggalLahir) {
    try {
      final today = DateTime.now();
      final dob = _toDate(tanggalLahir);
      if (dob == null) return -1;
      final birthDay = dob.day;
      final birthMonth = dob.month;
      final nextBirthday = DateTime(today.year, birthMonth, birthDay);

      final birthday =
          nextBirthday.isBefore(today)
              ? DateTime(today.year + 1, birthMonth, birthDay)
              : nextBirthday;

      return birthday.difference(today).inDays;
    } catch (_) {
      return -1;
    }
  }

  Widget _buildCustomerCard(Map<String, dynamic> data) {
    final name = data['Customer_Name'] ?? '-';
    final phone = data['No_HP'] ?? '-';
    final tanggalLahir = data['Tanggal_Lahir'];
    final parsedDobForDisplay = _toDate(tanggalLahir);
    final tanggalLahirDisplay =
        parsedDobForDisplay != null
            ? DateFormat('dd/MM/yyyy').format(parsedDobForDisplay)
            : (tanggalLahir?.toString() ?? '-');
    final customerId = data['ID'] ?? 'N/A';
    final message = _generateMessage(name, tanggalLahir);
    final daysUntilBirthday = _getDaysUntilBirthday(tanggalLahir);

    final today = DateTime.now();
    final dob = _toDate(data['Tanggal_Lahir']);
    final birthDay = dob?.day ?? 1;
    final birthMonth = dob?.month ?? 1;
    final nextBirthday = DateTime(today.year, birthMonth, birthDay);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 24),
          ),
          title: Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cake, size: 14, color: Colors.red.shade600),
                      const SizedBox(width: 4),
                      Text(
                        tanggalLahirDisplay,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade700),
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.grey.shade50, Colors.white],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header divider
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.red.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Model & Tanggal SPK
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.directions_car,
                                    size: 20,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Model",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${data['Model'] ?? '-'}",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Colors.orange.shade700,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${data['Tanggal_Spk_Do'] ?? '-'}",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Hobby (if exists)
                    if ((data['Hobby'] ?? '').toString().trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.sports_esports,
                                size: 20,
                                color: Colors.purple.shade600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Hobi",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "${data['Hobby']}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Makanan Favorit (if exists)
                    if ((data['Makanan_Favorit'] ?? '')
                        .toString()
                        .trim()
                        .isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.fastfood,
                                size: 20,
                                color: Colors.green.shade600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Makanan Favorit",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "${data['Makanan_Favorit']}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            final includeForm =
                                nextBirthday.difference(today).inDays == 6;
                            _editMessage(name, phone, message, customerId);
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (nextBirthday.difference(today).inDays == 6)
                          ElevatedButton.icon(
                            onPressed: () {
                              _sendWhatsAppWithForm(
                                name,
                                customerId,
                                phone,
                                message,
                              );
                            },
                            icon: const Icon(
                              FontAwesomeIcons.whatsapp,
                              size: 18,
                            ),
                            label: const Text('Form'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () {
                              _openWhatsApp(phone, message);
                            },
                            icon: const Icon(
                              FontAwesomeIcons.whatsapp,
                              size: 18,
                            ),
                            label: const Text('WhatsApp'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthNow = DateFormat('MMMM', 'id_ID').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section with Gradient
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade600, Colors.red.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Cari berdasarkan $_filter...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.red.shade600,
                                size: 22,
                              ),
                              suffixIcon:
                                  _searchText.isNotEmpty
                                      ? IconButton(
                                        icon: Icon(
                                          Icons.clear,
                                          color: Colors.grey.shade400,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchText = '');
                                        },
                                      )
                                      : null,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.red.shade300,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: PopupMenuButton<String>(
                          icon: Icon(
                            Icons.filter_list,
                            color: Colors.red.shade600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          offset: const Offset(0, 45),
                          onSelected: (val) {
                            setState(() => _filter = val);
                          },
                          itemBuilder:
                              (context) => [
                                PopupMenuItem(
                                  value: "nama",
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        size: 20,
                                        color:
                                            _filter == "nama"
                                                ? Colors.red.shade600
                                                : Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "Nama",
                                        style: TextStyle(
                                          color:
                                              _filter == "nama"
                                                  ? Colors.red.shade600
                                                  : Colors.black87,
                                          fontWeight:
                                              _filter == "nama"
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: "no_rangka",
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.numbers,
                                        size: 20,
                                        color:
                                            _filter == "no_rangka"
                                                ? Colors.red.shade600
                                                : Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "Nomor Rangka",
                                        style: TextStyle(
                                          color:
                                              _filter == "no_rangka"
                                                  ? Colors.red.shade600
                                                  : Colors.black87,
                                          fontWeight:
                                              _filter == "no_rangka"
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: "model",
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.directions_car,
                                        size: 20,
                                        color:
                                            _filter == "model"
                                                ? Colors.red.shade600
                                                : Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "Model",
                                        style: TextStyle(
                                          color:
                                              _filter == "model"
                                                  ? Colors.red.shade600
                                                  : Colors.black87,
                                          fontWeight:
                                              _filter == "model"
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content Section
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getCustomerStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.red.shade600,
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Memuat data...',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Tidak ada data pelanggan.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final allDocs =
                      snapshot.data!.docs
                          .map((e) => e.data() as Map<String, dynamic>)
                          .toList();

                  final searchResults =
                      _searchText.isEmpty
                          ? []
                          : allDocs.where((data) {
                            final name =
                                (data['Customer_Name'] ?? '')
                                    .toString()
                                    .toLowerCase();
                            final model =
                                (data['Model'] ?? '').toString().toLowerCase();
                            final noRangka =
                                (data['No_Rangka'] ?? '')
                                    .toString()
                                    .toLowerCase();

                            if (_filter == "nama")
                              return name.contains(_searchText);
                            if (_filter == "model")
                              return model.contains(_searchText);
                            return noRangka.contains(_searchText);
                          }).toList();

                  final nearestMonth = DateTime.now().month;
                  final nearestList =
                      allDocs.where((data) {
                        try {
                          final spkDo = data['Tanggal_Spk_Do'];
                          final dtSpk = _toDate(spkDo);
                          if (dtSpk == null) return false;
                          return dtSpk.month == nearestMonth;
                        } catch (_) {
                          return false;
                        }
                      }).toList();

                  return ListView(
                    padding: const EdgeInsets.only(top: 16, bottom: 12),
                    children: [
                      if (_searchText.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.search,
                                  color: Colors.blue.shade600,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Hasil Pencarian",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      "${searchResults.length} customer ditemukan",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (searchResults.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 60,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Tidak ada hasil ditemukan.",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...searchResults
                              .map((data) => _buildCustomerCard(data))
                              .toList(),
                        const SizedBox(height: 24),
                      ],

                      // Nearest Date Section
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.calendar_month,
                                color: Colors.orange.shade600,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Nearest Date $monthNow",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    "${nearestList.length} customer bulan ini",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (nearestList.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  size: 60,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Tidak ada customer bulan ini.",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
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
