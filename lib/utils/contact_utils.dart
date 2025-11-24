import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class ContactUtils {
  static Future<void> makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch $phoneUri';
    }
  }

  static Future<void> openZalo(String phoneNumber) async {
    // Zalo deep link format: zalo://chat?phone=phoneNumber
    final Uri zaloUri = Uri.parse('zalo://chat?phone=$phoneNumber');
    
    if (await canLaunchUrl(zaloUri)) {
      await launchUrl(zaloUri);
    } else {
      // Fallback to Zalo web if app not installed
      final Uri webUri = Uri.parse('https://zalo.me/$phoneNumber');
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    }
  }

  static Future<void> copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã sao chép vào clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

