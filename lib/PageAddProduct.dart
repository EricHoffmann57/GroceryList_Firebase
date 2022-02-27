import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:transparent_image/transparent_image.dart';

// ignore: camel_case_types
class PageAddProduct extends StatefulWidget {
  const PageAddProduct({Key? key}) : super(key: key);

  @override
  _PageAddProductState createState() => _PageAddProductState();
}

class _PageAddProductState extends State<PageAddProduct> {
  FirebaseStorage storage = FirebaseStorage.instance;

  //text fields controllers
  // ignore: prefer_final_fields
  late TextEditingController _imageController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  CollectionReference groceryProducts =
      FirebaseFirestore.instance.collection('Grocery-products');

  //var for search filter on collection
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> documents = [];
  String searchText = "";

  @override
  void initState() {
    super.initState();
    pickedFile;
  }

  final picker = ImagePicker();
  //initializer for future image from camera or gallery with a starting null value
  Future<XFile?> pickedFile = Future.value(null);
  //initializer for converting image file to base64 for stroing in firebase database
  Uint8List? imgbytes;

  //This function is triggered when the floatting button or one of the edit buttons is pressed
  // Adding a product if no documentSnapshot is passed
  //If documentSnapshot != null then update an existing product
  Future<void> _createOrUpdate([DocumentSnapshot? documentSnapshot]) async {
    String action = 'create';
    //_imageController.text = '';
    _nameController.text = '';
    if (documentSnapshot != null) {
      action = 'update';
      _imageController.text = documentSnapshot['image'];
      _nameController.text = documentSnapshot['name'];
    }
    //modal to create/update product
    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext ctx) {
          return Expanded(
              child: Padding(
                  padding: EdgeInsets.only(
                      top: 10,
                      left: 20,
                      right: 20,
                      // prevent the soft keyboard from covering text fields
                      bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
                  //prevents bottom overflowing due to soft keyboard :/
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _backIconButton(),
                        _chooseImageTextField(),
                        _imagePicker(),
                        _futureFileBuilder(),
                        const SizedBox(
                          height: 20,
                        ),
                        _imageTextField(),
                        _nameTextField(),
                        const SizedBox(
                          height: 20,
                        ),
                        ElevatedButton(
                          child: Text(action == 'create' ? 'Create' : 'Update'),
                          onPressed: () async {
                            final String? image = _imageController.text;
                            final String? name = _nameController.text;
                            if (image != "" && name != "") {
                              if (action == 'create') {
                                // Persist a new product to Firestore
                                await groceryProducts
                                    .add({"image": image, "name": name});
                              }

                              if (action == 'update') {
                                // Update the product
                                await groceryProducts
                                    .doc(documentSnapshot!.id)
                                    .update({"image": image, "name": name});
                              }

                              // Clear the text fields
                              _imageController.text = '';
                              _nameController.text = '';

                              // Hide the bottom sheet
                              Navigator.of(context).pop();
                            }
                          },
                        )
                      ],
                    ),
                  )));
        });
  }

  Widget _backIconButton() {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: 15,
            left: 25,
          ),
          child: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
      ],
    );
  }

  Widget _chooseImageTextField() {
    return const SizedBox(
      width: 200,
      height: 30,

      // ignore: prefer_const_literals_to_create_immutables
      child: TextField(
        decoration: InputDecoration(
          border: UnderlineInputBorder(),
          labelText: '  Sélectionnez votre image',
        ),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _imagePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
            onPressed: () async {
              pickedFile = picker
                  .pickImage(source: ImageSource.camera, maxWidth: 225)
                  .whenComplete(() => {
                        setState(() {
                          pickedFile;
                        })
                      });
              //Navigator.of(context).pop();
            },
            icon: const Icon(Icons.camera)),
        const SizedBox(
          width: 100,
        ),
        IconButton(
          onPressed: () async {
            pickedFile = picker
                .pickImage(source: ImageSource.gallery, maxWidth: 225)
                .whenComplete(() => {
                      setState(() {
                        pickedFile;
                      })
                    });
            //Navigator.of(context).pop();
          },
          icon: const Icon(Icons.image_search_outlined),
        ),
      ],
    );
  }

  Widget _imageTextField() {
    return TextField(
        readOnly: true,
        decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 40),
            prefixIcon: (_imageController.text != '')
                ? Image.memory(
                    base64Decode((_imageController.text.split(',').last)),
                    fit: BoxFit.scaleDown,
                    width: 50,
                  )
                : FadeInImage.memoryNetwork(
                    placeholder: kTransparentImage,
                    image: 'https://picsum.photos/250?image=1080',
                    fit: BoxFit.scaleDown,
                    width: 50)));
  }

  Widget _nameTextField() {
    return TextField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Nom du produit',
      ),
      textAlign: TextAlign.start,
    );
  }

  Widget _futureFileBuilder() {
    return FutureBuilder<XFile?>(
      future: pickedFile,
      builder: (context, snap) {
        if (snap.hasData) {
          File file = File(snap.data!.path);
          Uint8List fileInByte = file.readAsBytesSync();
          String fileInBase64 =
              "data:image/jpeg;base64," + base64Encode(fileInByte);
          //convert file to base64 and hydrate _imageController
          _imageController.text = fileInBase64;

          return Container(
            height: 75.0,
            color: Colors.blue.shade50,
            child: Image.file(
              file,
              fit: BoxFit.scaleDown,
              width: double.infinity,
            ),
          );
        }
        //show empty container if image file is not available
        return Container(
          height: 75.0,
          color: Colors.blue.shade50,
          child: FadeInImage.memoryNetwork(
            placeholder: kTransparentImage,
            image: 'https://picsum.photos/250?image=1080',
            width: double.infinity,
          ),
        );
      },
    );
  }

  // Deleting a product by id
  Future<void> _deleteProduct(String productId) async {
    await groceryProducts.doc(productId).delete();

    // Show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous avez supprimé un produit!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.lightBlue.shade200,
        title: const Text('Ajouter/Modifier un produit'),
        centerTitle: true,
      ),
      body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            Expanded(
              // Using StreamBuilder to display all products from Firestore in real-time
              child: StreamBuilder(
                stream: groceryProducts.snapshots(),
                builder:
                    (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                  if (streamSnapshot.hasData) {
                    documents = streamSnapshot.data!.docs;
                    //Documents list added to filterName of products
                    if (searchText.isNotEmpty) {
                      documents = documents.where((element) {
                        return element
                            .get('name')
                            .toString()
                            .toLowerCase()
                            .contains(searchText.toLowerCase());
                      }).toList();
                    }
                    return ListView.builder(
                      //limit products shown in ListView to last 5
                      itemCount: documents.length < 5 ? documents.length : 5,
                      itemBuilder: (context, index) {
                        final DocumentSnapshot documentSnapshot =
                            documents[index];

                        Uint8List bytes = base64
                            .decode(documents[index]['image'].split(',').last);
                        return Card(
                          margin: const EdgeInsets.all(10),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.green[100],
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(70),
                                child: Image.memory(bytes),
                              ),
                            ),
                            title: Text(
                              documents[index]['name'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.blueGrey,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: SizedBox(
                              width: 100,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Press this button to edit a single product
                                  IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () =>
                                          _createOrUpdate(documentSnapshot)),
                                  // This icon button is used to delete a single product
                                  IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () =>
                                          _deleteProduct(documentSnapshot.id)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }

                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              ),
            )
          ])),
      // Add new product
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrUpdate(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
