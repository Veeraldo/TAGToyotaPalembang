import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../util/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Pengaturan"),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.primaryColor,
        foregroundColor: theme.appBarTheme.foregroundColor ?? Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),

          // Kartu Mode Gelap / Terang
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isDarkMode ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded,
                        color: isDarkMode ? Colors.amberAccent : Colors.grey[800],
                      ),
                      const SizedBox(width: 16),
                      Text(
                        isDarkMode ? "Mode Terang" : "Mode Gelap",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  Switch.adaptive(
                    value: themeProvider.isDarkMode,
                    activeColor: Colors.amberAccent,
                    onChanged: (value) => themeProvider.toggleTheme(value),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Kartu Tentang Aplikasi
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            child: ListTile(
              leading: Icon(Icons.info_outline,
                  color: isDarkMode ? Colors.white70 : Colors.grey[800]),
              title: Text(
                "Tentang Aplikasi",
                style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500),
              ),
              trailing: Icon(Icons.arrow_forward_ios,
                  size: 16, color: isDarkMode ? Colors.white54 : Colors.black54),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'TAG Toyota',
                  applicationVersion: 'v1.0.0',
                  applicationIcon: const Icon(Icons.car_rental, size: 40),
                  children: const [
                    Text(
                        'Aplikasi ini dikembangkan oleh Mahasiswa Universitas Multi Data Palembang, Veraldo 2327250001, Siti Fatimah AzZahrah'),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Kartu Bantuan
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            child: ListTile(
              leading: Icon(Icons.help_outline,
                  color: isDarkMode ? Colors.white70 : Colors.grey[800]),
              title: Text(
                "Bantuan",
                style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500),
              ),
              trailing: Icon(Icons.arrow_forward_ios,
                  size: 16, color: isDarkMode ? Colors.white54 : Colors.black54),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fitur Bantuan belum tersedia.'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
