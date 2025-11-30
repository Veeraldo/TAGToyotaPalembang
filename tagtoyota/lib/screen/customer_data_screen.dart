import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CustomerDataScreen extends StatefulWidget {
  const CustomerDataScreen({super.key});

  @override
  State<CustomerDataScreen> createState() => _CustomerDataScreenState();
}

class _CustomerDataScreenState extends State<CustomerDataScreen> {
  List<Map<String, dynamic>> _excelData = [];
  final DateFormat _excelDateFormat = DateFormat('dd/MM/yyyy');
  bool _isLoading = false;

  Future<void> _pickExcelFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isLoading = true);

        final path = result.files.single.path!;

        final tempData = await compute(_parseExcelInBackground, {
          'path': path,
          'dateFormat': _excelDateFormat.pattern,
        });

        print('DEBUG - Parsed Excel Data: $tempData');

        setState(() {
          _excelData = List<Map<String, dynamic>>.from(tempData);
          _isLoading = false;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('${_excelData.length} data berhasil dimuat!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Text('Gagal memuat file Excel: $e'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _uploadToFirebase() async {
    if (_excelData.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.cloud_upload, color: Colors.green),
            SizedBox(width: 12),
            Text('Konfirmasi Upload'),
          ],
        ),
        content: Text(
          'Upload ${_excelData.length} data customer ke Firebase?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Upload'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => _isLoading = true);

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      for (var data in _excelData) {
        final docRef = firestore.collection('customers').doc();
        batch.set(docRef, data);
      }

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Data berhasil diunggah!'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      setState(() {
        _excelData.clear();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Text('Gagal upload data: $e'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          "Isi Data Customer",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey.shade200,
            height: 1,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.red.shade600,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Memproses data...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade600, Colors.red.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.upload_file,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Import Data Excel",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _excelData.isEmpty
                            ? "Belum ada data dimuat"
                            : "${_excelData.length} data customer siap diupload",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _pickExcelFile,
                        icon: const Icon(Icons.folder_open, size: 20),
                        label: const Text(
                          "Pilih File Excel",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content Section
                Expanded(
                  child: _excelData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.table_chart_outlined,
                                size: 80,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Belum ada data",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Pilih file Excel untuk memulai",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            // Stats Card
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.table_rows,
                                        color: Colors.blue.shade600,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${_excelData.length}",
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            "Total Data Customer",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.green.shade600,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Table Section
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SingleChildScrollView(
                                      child: DataTable(
                                        headingRowColor:
                                            MaterialStateProperty.all(
                                          Colors.grey.shade100,
                                        ),
                                        headingTextStyle: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade800,
                                          fontSize: 13,
                                        ),
                                        dataTextStyle: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 12,
                                        ),
                                        border: TableBorder.all(
                                          color: Colors.grey.shade200,
                                          width: 1,
                                        ),
                                        columns: const [
                                          DataColumn(
                                            label: Text('No Rangka'),
                                          ),
                                          DataColumn(
                                            label: Text('Customer Name'),
                                          ),
                                          DataColumn(
                                            label: Text('Tanggal Lahir'),
                                          ),
                                          DataColumn(label: Text('Model')),
                                          DataColumn(
                                            label: Text('Tanggal SPK/DO'),
                                          ),
                                          DataColumn(label: Text('No HP')),
                                          DataColumn(label: Text('Hobby')),
                                          DataColumn(
                                            label: Text('Makanan Favorit'),
                                          ),
                                        ],
                                        rows: _excelData
                                            .map(
                                              (data) => DataRow(
                                                cells: [
                                                  DataCell(
                                                    Text(
                                                      data['No_Rangka'] ?? '',
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      data['Customer_Name'] ??
                                                          '',
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      data['Tanggal_Lahir'] ??
                                                          '',
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(data['Model'] ?? ''),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      data['Tanggal_Spk_Do'] ??
                                                          '',
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(data['No_HP'] ?? ''),
                                                  ),
                                                  DataCell(
                                                    Text(data['Hobby'] ?? ''),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      data['Makanan_Favorit'] ??
                                                          '',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Upload Button
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green.shade600,
                                      Colors.green.shade800,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: _uploadToFirebase,
                                  icon: const Icon(
                                    Icons.cloud_upload,
                                    size: 22,
                                  ),
                                  label: const Text(
                                    "Upload ke Firebase",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    minimumSize:
                                        const Size(double.infinity, 56),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}

List<Map<String, dynamic>> _parseExcelInBackground(Map args) {
  final file = File(args['path']);
  final bytes = file.readAsBytesSync();
  final excel = Excel.decodeBytes(bytes);
  final dateFormat = DateFormat(args['dateFormat']);

  String parse(dynamic value) {
    if (value == null) return '';
    // Jika value DateTime, format ke dd/MM/yyyy
    if (value is DateTime) {
      return DateFormat('dd/MM/yyyy').format(value);
    }
    // Jika value angka (serial Excel), konversi ke DateTime lalu format
    if (value is num) {
      try {
        final millis = ((value - 25569) * 86400000).toInt();
        final dt = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true)
            .toLocal();
        return DateFormat('dd/MM/yyyy').format(dt);
      } catch (_) {
        return value.toString();
      }
    }
    // Jika value string, coba parse ke DateTime dulu
    if (value is String) {
      final s = value.trim();
      if (s.isEmpty) return '';
      try {
        final dt = DateFormat('dd/MM/yyyy').parseStrict(s);
        return DateFormat('dd/MM/yyyy').format(dt);
      } catch (_) {
        // Jika gagal, return string apa adanya
        return s;
      }
    }
    return value.toString();
  }

  List<Map<String, dynamic>> tempData = [];

  for (var table in excel.tables.keys) {
    var sheet = excel.tables[table]!;

    for (var i = 1; i < sheet.rows.length; i++) {
      var row = sheet.rows[i];
      print('DEBUG - Processing row SPK ${row[4]?.value}');
      tempData.add({
        'No_Rangka': row[0]?.value?.toString() ?? '',
        'Customer_Name': row[1]?.value?.toString() ?? '',
        'Tanggal_Lahir': parse(row[2]?.value),
        'Model': row[3]?.value?.toString() ?? '',
        'Tanggal_Spk_Do': parse(row[4]?.value),
        'No_HP': row[5]?.value?.toString() ?? '',
        'Hobby': row[6]?.value?.toString() ?? '',
        'Makanan_Favorit': row[7]?.value?.toString() ?? '',
      });

      print('DEBUG - Added row ${i}: ${tempData.last}');
    }
  }

  return tempData;
}