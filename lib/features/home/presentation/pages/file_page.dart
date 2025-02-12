import 'package:flutter/material.dart';

class FilePage extends StatelessWidget {
  const FilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Daftar folder (bisa diganti dengan data dari backend)
    final List<String> folders = [
      "Documents",
      "Pictures",
      "Videos",
      "Music",
      "Downloads",
      "Projects",
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Files"),
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView.builder(
        itemCount: folders.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: const Icon(Icons.folder, color: Colors.amber, size: 30),
              title: Text(
                folders[index],
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Aksi saat folder diklik
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Opening ${folders[index]}...")),
                );
              },
            ),
          );
        },
      ),
    );
  }
}