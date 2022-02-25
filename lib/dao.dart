import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'Produit.dart';
import 'dart:convert';

class DAO {
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  static Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/produits.txt');
  }

  static Future<File> writeProduct(Product p) async {
    final file = await _localFile;
    return file.writeAsString(json.encode(p.toJson()));
  }

  static Future<Product?> readProduct() async {
    try {
      final file = await _localFile;

      final contents = await file.readAsString();

      return Product.fromJson(contents);
    } catch (e) {
      return null;
    }
  }
}
