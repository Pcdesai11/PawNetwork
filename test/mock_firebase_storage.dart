import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// A simple mock implementation of Firebase Storage for testing
class MockFirebaseStorage {
  final Map<String, Uint8List> _files = {};

  /// Upload data to a specified path
  Future<String> uploadData({
    required String path,
    required Uint8List data,
  }) async {
    _files[path] = data;
    return path;
  }

  /// Get a download URL for a file
  Future<String> getDownloadURL(String path) async {
    if (!_files.containsKey(path)) {
      // Create a fake URL even if the file doesn't exist
      return 'https://fake-storage.example.com/$path';
    }
    return 'https://fake-storage.example.com/$path';
  }

  /// Delete a file at a specified path
  Future<void> deleteFile(String path) async {
    _files.remove(path);
  }

  /// List all files in the mock storage
  List<String> listFiles() {
    return _files.keys.toList();
  }

  /// Check if a file exists at the specified path
  bool fileExists(String path) {
    return _files.containsKey(path);
  }

  /// Reset the mock storage by removing all files
  void reset() {
    _files.clear();
  }

  /// For debugging - print all files in storage
  void debugPrintFiles() {
    debugPrint('MockFirebaseStorage files:');
    _files.forEach((key, value) {
      debugPrint('- $key (${value.length} bytes)');
    });
  }
}