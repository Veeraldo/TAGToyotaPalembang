import 'package:url_launcher/url_launcher.dart';

class GoogleFormHelper {
  // Form URL kamu
  static const String formBaseUrl = 'https://docs.google.com/forms/d/e/1FAIpQLSfiAbdyoF0pXJmxgU2umUQrL3jphj8skKlWm5pEhAAHsZcmIQ/viewform';
  
  // Entry ID dari form kamu
  static const String idFieldEntry = 'entry.1412436393';      // Field ID Customer
  static const String nameFieldEntry = 'entry.1981046888';    // Field Nama Customer

  /// Generate pre-filled Google Form URL
  /// 
  /// Parameter:
  /// - customerId: ID customer (misal: 1234)
  /// - customerName: Nama customer (misal: Jonathan)
  /// 
  /// Return: URL yang sudah di-prefill dengan ID dan Nama
  static String generateFormUrl(String customerId, String customerName) {
    final encodedId = Uri.encodeQueryComponent(customerId);
    final encodedName = Uri.encodeQueryComponent(customerName);
    
    return '$formBaseUrl?$idFieldEntry=$encodedId&$nameFieldEntry=$encodedName';
  }

  /// Kirim ke WhatsApp dengan link Google Form yang sudah di-prefill
  /// 
  /// Parameter:
  /// - phoneNumber: Nomor WhatsApp (format: 62812345678, tanpa +)
  /// - customerId: ID customer
  /// - customerName: Nama customer
  /// - additionalMessage: Pesan tambahan sebelum link form (optional)
  static Future<void> sendFormToWhatsApp({
    required String phoneNumber,
    required String customerId,
    required String customerName,
    String additionalMessage = '',
  }) async {
    try {
      final formUrl = generateFormUrl(customerId, customerName);
      
      // Compose pesan dengan link form
      String message = '''Halo $customerName,

$additionalMessage

Silakan isi form berikut untuk melanjutkan:
$formUrl

ID dan Nama kamu sudah terisi otomatis di form.

Terima kasih!'''.trim();

      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = 'https://wa.me/$phoneNumber?text=$encodedMessage';

      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
      } else {
        throw 'WhatsApp tidak terinstall atau nomor tidak valid';
      }
    } catch (e) {
      throw 'Error: $e';
    }
  }

  /// Buka form langsung di browser (tanpa WhatsApp)
  static Future<void> openFormInBrowser({
    required String customerId,
    required String customerName,
  }) async {
    try {
      final formUrl = generateFormUrl(customerId, customerName);
      
      if (await canLaunchUrl(Uri.parse(formUrl))) {
        await launchUrl(Uri.parse(formUrl), mode: LaunchMode.externalApplication);
      } else {
        throw 'Tidak bisa membuka URL';
      }
    } catch (e) {
      throw 'Error: $e';
    }
  }
}