import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

import 'Produit.dart';

class Storage {
  static List<Product> savedList = [];
  static late List<Product> items = [];
  static List storageList = [];

  static final grocery = GetStorage();

  static void addAndStoreProduct(Product product) {
    //avoidind dupes product in storage list
    var contain = savedList.where((element) => element.name == product.name);
    if (contain.isEmpty) {
      savedList.add(product);

      final storageMap = {}; // temporary map that gets added to storage
      final index = savedList.length; // for unique map keys
      final imageKey = 'image$index';
      final nameKey = 'name$index';
      final isCheckedKey = 'isChecked$index';

// adding task properties to temporary map
      storageMap[imageKey] = product.image;
      storageMap[nameKey] = product.name;
      storageMap[isCheckedKey] = product.isChecked;

      storageList.add(storageMap); // adding temp map to storageList
      grocery.write('products', storageList);
    }
  }

  static void restoreProducts() {
    if (storageList.isNotEmpty) {
      storageList = grocery.read('products'); // initializing list from storage
      String imageKey, nameKey, isCheckedKey;

// looping through the storage list to parse out Product objects from maps
      for (int i = 0; i < storageList.length; i++) {
        final map = storageList[i];
        // index for retrieval keys accounting for index starting at 0
        final index = i + 1;

        imageKey = 'image$index';
        nameKey = 'name$index';
        isCheckedKey = 'isChecked$index';

        // recreating Product objects from storage

        final product = Product(
            image: map[imageKey],
            name: map[nameKey],
            isChecked: map[isCheckedKey]);

        savedList.add(product); // adding products back to normal Product list
      }
    }
  }

  // looping through savedlist to see whats inside
  static printProducts(items) {
    for (int i = 0; i < savedList.length; i++) {
      items.add(savedList[i]);
      debugPrint(
          'Product ${i + 1} image: ${savedList[i].image} name: ${savedList[i].name} isChecked: ${savedList[i].isChecked}');
    }
    return items;
  }

  static void clearProducts() {
    savedList.clear();
    storageList.clear();
    grocery.erase();
  }
}
