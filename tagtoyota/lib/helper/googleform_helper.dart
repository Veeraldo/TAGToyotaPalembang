import 'package:url_launcher/url_launcher.dart';

class GoogleFormHelper {
  // TinyURL yang otomatis forward parameter
  static const String formBaseUrl = 'https://tinyurl.com/TunasAutoGraha';
  
  /// Generate URL dengan parameter
  static String generateFormUrl(String customerId, String customerName) {
    final encodedId = Uri.encodeQueryComponent(customerId);
    final encodedName = Uri.encodeQueryComponent(customerName);
    
    // TinyURL akan otomatis forward parameter ke GitHub Pages
    final url = '$formBaseUrl?customer_id=$encodedId&customer_name=$encodedName';
    
    print('DEBUG - Short URL: $url');
    return url;
  }

  /// Kirim form via WhatsApp
  static Future<void> sendFormToWhatsApp({
    required String phoneNumber,
    required String customerId,
    required String customerName,
    String additionalMessage = '',
  }) async {
    try {
      final formUrl = generateFormUrl(customerId, customerName);

      String message = '''Halo $customerName,

${additionalMessage.isNotEmpty ? '$additionalMessage\n\n' : ''}Silakan isi form preferensi Anda:
$formUrl

ID dan Nama sudah terisi otomatis.

Terima kasih!'''.trim();

      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = 'https://wa.me/$phoneNumber?text=$encodedMessage';

      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(
          Uri.parse(whatsappUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'WhatsApp tidak terinstall';
      }
    } catch (e) {
      throw 'Error: $e';
    }
  }

  /// Buka form di browser
  static Future<void> openFormInBrowser({
    required String customerId,
    required String customerName,
  }) async {
    try {
      final formUrl = generateFormUrl(customerId, customerName);
      
      if (await canLaunchUrl(Uri.parse(formUrl))) {
        await launchUrl(
          Uri.parse(formUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Tidak bisa membuka URL';
      }
    } catch (e) {
      throw 'Error: $e';
    }
  }
}