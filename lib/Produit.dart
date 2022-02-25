import 'dart:convert';

import 'dart:core';

class Product {
  String image;
  String name;
  bool isChecked;

  getImage() {
    return image;
  }

  setImage(String image) {
    this.image = image;
  }

  getName() {
    return name;
  }

  setName(String name) {
    this.name = name;
  }

  isIsChecked() {
    return isChecked;
  }

  setIsChecked(bool isChecked) {
    this.isChecked = isChecked;
  }

  Product({this.image = '', this.name = '', this.isChecked = false});
  // Map toJson() => {'image': image, 'name': name, 'isChecked': isChecked};

  Product.fromJson(String jsonString)
      : image = '',
        name = '',
        isChecked = false {
    Map<String, dynamic> jsonObject = json.decode(jsonString);
    image = jsonObject['image'];
    name = jsonObject['name'];
    isChecked = jsonObject['isChecked'];
  }

  @override
  String toString() {
    return image + ' / ' + name + ' / ' + (isChecked ? "true" : "false");
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = <String, dynamic>{};
    data["image"] = image;
    data["name"] = name;
    data["isChecked"] = isChecked;
    return data;
  }

  static Map<String, dynamic> toMap(Product product) => {
        'image': product.image,
        'name': product.name,
        'isChecked': product.isChecked,
      };

  static String encode(List<Product> items) => json.encode(
        items.map<Map<String, dynamic>>((item) => Product.toMap(item)).toList(),
      );

  static List<Product> decode(String items) =>
      (json.decode(items) as List<dynamic>)
          .map<Product>((item) => Product.fromJson(item))
          .toList();
}
