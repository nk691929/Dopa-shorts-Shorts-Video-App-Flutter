import 'dart:ui';
import 'package:flutter/material.dart';

class CustomDialog {
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    required VoidCallback onConfirmed,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      barrierColor: Colors.black.withOpacity(0.3), // 👈 dim + transparent
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6), // 👈 blur strength
          child: AlertDialog(
            backgroundColor: Colors.grey.shade900.withOpacity(0.9), // 👈 frosted effect
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(icon, color: Colors.pink),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.pink,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink, // background
                  foregroundColor: Colors.white, // text
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  onConfirmed(); // Call the function
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }
}
