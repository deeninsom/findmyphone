import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FileScreen extends StatefulWidget {
  const FileScreen({super.key});

  @override
  _FileScreenState createState() => _FileScreenState();
}

class _FileScreenState extends State<FileScreen> {
  late Future<List<Directory>> _directories;

  @override
  void initState() {
    super.initState();
    requestPermission();
    _directories = _getDirectories();
  }

  // Request storage permission
  Future<void> requestPermission() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      print("Permission granted");
    } else {
      print("Permission denied");
    }
  }

  // Method to get directories from the external storage
  Future<List<Directory>> _getDirectories() async {
    final directoryPath = await getExternalStoragePath();
    final directory = Directory(directoryPath);
    List<FileSystemEntity> entities = directory.listSync();
    List<Directory> directories = [];

    for (var entity in entities) {
      if (entity is Directory) {
        directories.add(entity);
      }
    }

    return directories;
  }

  // Get external storage path
  Future<String> getExternalStoragePath() async {
    final directory = await getExternalStorageDirectory();
    return directory!.path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Storage'),
      ),
      body: FutureBuilder<List<Directory>>(
        future: _directories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No folders found.'));
          }

          // Display the list of directories (folders)
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final directory = snapshot.data![index];
              return ListTile(
                leading: const Icon(Icons.folder),
                title: Text(directory.path.split('/').last), // Display folder name
                onTap: () {
                  // Navigate to the folder detail screen to show files inside
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FolderDetailScreen(directory: directory),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class FolderDetailScreen extends StatelessWidget {
  final Directory directory;

  const FolderDetailScreen({super.key, required this.directory});

  // Method to get files from the folder
  Future<List<FileSystemEntity>> _getFiles() async {
    List<FileSystemEntity> entities = directory.listSync();
    return entities;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(directory.path.split('/').last), // Display folder name in the AppBar
      ),
      body: FutureBuilder<List<FileSystemEntity>>(
        future: _getFiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No files found in this folder.'));
          }

          // Display the list of files in the selected folder
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final file = snapshot.data![index];
              return ListTile(
                leading: Icon(file is Directory
                    ? Icons.folder
                    : Icons.insert_drive_file),
                title: Text(file.uri.pathSegments.last),
                onTap: () {
                  // You can add more functionality here for opening files
                  // e.g., viewing or deleting the file
                },
              );
            },
          );
        },
      ),
    );
  }
}
