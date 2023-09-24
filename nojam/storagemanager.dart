import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StorageManager {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory(); 
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/distance_data.json');
  }

  Future<Map<String, dynamic>> readData() async {
    try {
      final file = await _localFile;
      String contents = await file.readAsString();
      return json.decode(contents);
    } catch (e) {
      return {};
    }
  }

  Future<File> writeData(Map<String, dynamic> data) async {
    final file = await _localFile;
    return file.writeAsString(json.encode(data));
  }
}
