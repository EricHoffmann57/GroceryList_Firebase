import 'dart:convert';

import 'package:flutter/material.dart';
import 'Produit.dart';

class SecondPage extends StatefulWidget {
  const SecondPage(this.cart, {Key? key}) : super(key: key);
  //final List<Product> items;
  final List<Product> cart;
  List<Product> get products => cart;

  @override
  State<StatefulWidget> createState() {
    return SecondPageState();
  }
}

class SecondPageState extends State<SecondPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.lightBlue.shade200,
        appBar: AppBar(
          title: const Text('Mon caddie'),
          centerTitle: true,
          actions: <Widget>[
            Center(
                child: Ink(
              decoration: const ShapeDecoration(
                color: Colors.white,
                shape: CircleBorder(),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.delete_rounded,
                  color: Colors.red,
                ),
                onPressed: () {
                  setState(() {
                    widget.cart.clear();
                  });
                },
              ),
            ))
          ],
        ),
        body: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
            child: ListView(
              children: widget.cart
                  .where((element) => element.isChecked == true)
                  .map((element) {
                var index = widget.cart.indexOf(element);
                return cartListItems(element, index);
              }).toList(),
            ),
          ),
        ]));
  }

  Widget cartListItems(element, index) {
    return Card(
        child: ListTile(
            key: Key(index.toString()),
            // tileColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            leading: CircleAvatar(
              radius: 32,
              backgroundColor: Colors.green[100],
              child: ClipRRect(
                borderRadius: BorderRadius.circular(70),
                child: Image.memory(base64Decode(element.image)),
              ),
            ),
            title: Text(
              element.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Checkbox(
              activeColor: Colors.green[500],
              value: element.isChecked,
              onChanged: (val) {},
            )));
  }
}
