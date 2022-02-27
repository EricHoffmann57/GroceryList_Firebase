import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'PageAddProduct.dart';
import 'Produit.dart';
import 'SecondPage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Storage.dart';
import 'dao.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await GetStorage.init();
  runApp(const MaterialApp(
      debugShowCheckedModeBanner: false, home: GroceryList()));
}

class GroceryList extends StatefulWidget {
  const GroceryList({Key? key, name, image}) : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return GroceryListState();
  }
}

class GroceryListState extends State<GroceryList> {
  CollectionReference groceryProducts =
      FirebaseFirestore.instance.collection('Grocery-products');

  // Lancement de l'écran : lecture du fichier
  @override
  void initState() {
    super.initState();
    _getGroceryList();
    Storage.restoreProducts();
  }

  //for search filter on collection
  final TextEditingController _controller = TextEditingController();
  List<DocumentSnapshot> documents = [];
  String searchText = "";

  late List<Product> items = [];
  late List<Product> cart = [];
  final List<Product> save1 = [];
  final List<Product> savedList = [];
  final grocery = GetStorage();
  // separate list for storing maps/ restoreTask function
  //populates _tasks from this list on initState

  List storageList = [];

  // ignore: prefer_typing_uninitialized_variables
  var product;

  Future<void> products = FirebaseFirestore.instance
      .collection('Grocery-products')
      .get()
      .then((querySnapshot) {
    for (var element in querySnapshot.docs) {
      element['name'];
      element['image'];
    }
  });

  final Color oddItemColor = Colors.amber.shade300;
  final Color evenItemColor = Colors.amber.shade100;

  void _getGroceryList() async {
    var lastProduct = await DAO.readProduct();
    if (lastProduct != null) {
      var snackBar = SnackBar(
          content: Text('Dernier produit ajouté : ' +
              lastProduct
                  .toString()
                  .replaceAll('/ false', " ")
                  .split('/')
                  .last));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.lightGreen.shade100,
        appBar: AppBar(
          backgroundColor: Colors.green.shade400,
          title: const Text("Ma liste de courses"),
          centerTitle: true,
          actions: [
            _appBarActionBuilder1(),
            _appBarActionBuilder2(),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildFormField(),
            Expanded(
                child: StreamBuilder(
              stream: groceryProducts.snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                if (streamSnapshot.hasData) {
                  documents = streamSnapshot.data!.docs;
                  //Documents list added to filterName of products
                  if (searchText.isNotEmpty) {
                    documents = documents.where((element) {
                      return element['name'] == searchText.trim();
                    }).toList();
                  }
                  if (searchText != "") {
                    return ListView.builder(
                        //limit products shown in ListView to last 5
                        itemCount: documents.length <= 1 ? documents.length : 1,
                        itemBuilder: (context, index) {
                          Uint8List bytes = base64.decode(
                              documents[index]['image'].split(',').last);

                          product = Product(
                              image: documents[index]['image'].split(',').last,
                              name: searchText.trim(),
                              isChecked: false);
                          return _listViewCard(bytes);
                        });
                  }
                }
                return _ordenedListView();
              },
            )),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(width: 120, child: buildInsertButton()),
            ]),
            _footerButtons(),
          ],
        ),
      );

  Widget _appBarActionBuilder1() {
    return Builder(
      builder: (context) => IconButton(
        icon: Column(
          // ignore: prefer_const_literals_to_create_immutables
          children: [
            const Icon(Icons.add_shopping_cart_rounded),
          ],
        ),
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SecondPage(
                        (cart),
                      )));
        },
      ),
    );
  }

  Widget _appBarActionBuilder2() {
    return Builder(
      builder: (context) => IconButton(
        icon: Column(
          children: const [
            Icon(Icons.add_box_outlined),
          ],
        ),
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const PageAddProduct()));
        },
      ),
    );
  }

  Widget _buildFormField() {
    return TextFormField(
      style: const TextStyle(color: Colors.black38, fontSize: 22),
      textAlign: TextAlign.center,
      onChanged: (str) {
        setState(() {
          searchText = str;
        });
      },
      maxLength: 20,
      controller: _controller,
      decoration: const InputDecoration(
        hintText: 'Ajouter à la liste',
      ),
    );
  }

  void clearText() {
    _controller.clear();
  }

  Widget _ordenedListView() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ReorderableListView(
        proxyDecorator: _proxyDecorator,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final element = items.removeAt(oldIndex);
            items.insert(newIndex, element);
          });
        },
        itemExtent: 70.0,
        shrinkWrap: true,
        children: items.map<Widget>((Product element) {
          var index = items.indexOf(element);

          return _buildListOfItems(element, index);
        }).toList(),
      ),
    );
  }

  Widget _listViewCard(bytes) {
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
            searchText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.blueGrey,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ));
  }

  Widget _buildListOfItems(element, index) {
    return Dismissible(
      key: UniqueKey(),
      child: Card(
          elevation: 8,
          color: (index % 2 == 0) ? oddItemColor : evenItemColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
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
                onChanged: (val) {
                  setState(() {
                    element.setIsChecked(val);
                    if (val == true) {
                      cart.add(Product(
                          image: element.image,
                          name: element.name,
                          isChecked: element.isChecked));
                      items.removeAt(index);
                    }
                  });
                },
              ))),
      onDismissed: (direction) {
        setState(() {
          items.removeAt(index);
        });
      },
    );
  }

  Widget buildInsertButton() => ElevatedButton(
        child: const Text(
          "Ajouter produit",
          style: TextStyle(fontSize: 14),
          textAlign: TextAlign.center,
        ),
        style: ElevatedButton.styleFrom(
          primary: Colors.amber.shade800,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        ),
        onPressed: () {
          setState(() {
            if (documents.isNotEmpty && searchText != '') {
              items.add(product);
            } else if (documents.isEmpty) {
              var p = Product(
                  image:
                      "/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAoHCBUWEhgWFhUYGRgZGBgYHBoRGRgcFR4ZHBghGhwYGBocIy4lHh4rIRgeJjgmKy8xNTU1GiQ7QDs0Py40NTEBDAwMEA8QHxISHj0rJSw0ND4xNzQxMTE9NDQ6MTU9NDQ0NDQ0NDQ0PTE0NDQ0NDQ2NDExNDQxNDQ0NDQ0NDQ0NP/AABEIAM8A8wMBIgACEQEDEQH/xAAbAAEAAgMBAQAAAAAAAAAAAAAAAQUDBAYCB//EADoQAAECAwMKBAYDAQABBQAAAAEAAhEhMQMyQQQFEiJRYXGhscFygZHwBhMUUmLhQtHxI7IHM6LC0v/EABoBAQADAQEBAAAAAAAAAAAAAAABBAUDAgb/xAAoEQACAgEDAgYDAQEAAAAAAAAAAQIDEQQhMRJRBSIyYXGBEyNBoUL/2gAMAwEAAhEDEQA/APrl/dDzr/iX90POv+Jf3Q86/wCJf3Q86/4gIvypDz90S/KkPNL8qQ8/dEvypDzQC/KkPNTe1aQ89yX5Uh5pe1aQ89yAi9q0hjXcl7Vpo41pJL2rSGNdyXtWmjjwkgF7Vpo48JUS9q00ceEqJe1aaOPCSXtWmjjwlRCBe1aaOPCVFpZ0zgLNkCImjRtIlE7ApzhnFlm3RdGIoGzJhKmAXNZ0zh85zTo6Ia3RAjHiacPRV77lGLSe54lJJbcnq0zzbu/lAYBobDos7viC0Nnowbpfdu8NI7+SqEWerpr+s4dcu5YMzzbCrtIbHAQ5CK6fIcrFswQltjOBFQuIVjmzOfymuboaQc4OrCEoUgu1F7UsSex7hPD3Z11dTZjzoldTnzotPIM4Mtm6LTAiodX0x9VuV1OfOi0YyUllHdNPgn8OfOij8Of/AMqJ+HPnRT+HPnRSSR+HPnReXvDQWkgATJNPuovX4c+dFRZ2yyP/ADadVpmRi6NOAXG+5VRy/o6VVucsIjLM6OI0WGDdtHGfIKv0zGMTHbGa8osGy2Vkups1IVxgsJFrm3OJ/wDbcZGQcagnbtCu6am3HjuXHrp83ZRpWY2mRO+lPJaWgvcswk+OClqqlHEkbNNTbjx3Kburtx47kpq7ceO5Lurtx47lpFQi7q1jjxlRLurXSx4yol3VrHHjKiXdWuljxlRCCfpfy5ftQp+l/Ll+1CEi/SUPOv8AiX6Sh51/xL9JQ7/4l+kod/8AEAvypBL8qQS/ISgpvSEoIBflSCXtWkP8S9ISgl6QlD/EAvatIY8lF7VpDHhJL2qJQx5Je1aQx4SQC9q00ceEl4tbQaJBloAuJ3NE0tbVuidIhobMuNJSVLl+fWOaWNBdItiZAyhECq52WRgt2eZSS5KC3tnPcXOMSfYHAUXhEWO3ndlUIiIQEWSysHOutc7wgnot+xzFbO/iG73EDkInkvUa5S4R6UW+CvsrQscHNMCDELt8mtw9jQP5NBj5Rh2XJZfmu0sQC4AgyiwkiOwxAgveQ51fZjRjpN+04eE4dFYps/DJxme4y6XhnX/hz50T8OfOixZNlLbRgDTEHHHaQRtwWX8MdvNaSaayjuaec8q+WwtF4yB5x8lza2845RpWkjFrdVvrM+Z7LnstzvAlrADCrjTyHdYepm77GlwuDUogoQ35ZbLFlOUNY3SdSkqk7AqFudLUG8DuLRDksOU5W95BcaUAkFyjQ878HVyOiyXKmvBLYyqDULp8yO/5aO1xn5BcfmjJSxhLpF0JbAKR3zK7LM5/5AQvF0/P9KzoopXPHYr6p/r37m/TU248Uu6m3HilNXE48Uu6uJx4rYM8i7q1jjxkl3VrpY8ZJd1ak48ZJd1axx4yQgfSn7uSKfpj9yISRfpKHf8AxL9JQ7/4pv0lDv8A4l+kod/8QC9ISgl6QlBL9JQS9ISggF6QlBL0hKH+JekJQS9IShigIvaolDHkpvaokRjwkl7VEiMeSishIjHbggOX+IctLrTQF1kjvdiT09VULYy8EWrwa6T/APyK11jWSbm2ypJ5YREXg8l/mfMjXsD3k61A0wlGESVeWOa7FtLNvEiJ9TFVmYc62Ysgx7w0tiNcwBEYidMYK5ZlbCItcCNrZj1WnTGvpWEslmCjjYzgKVrOyrYPVY3ZQ7hwVk6GD4ge0ZO7SxgBxiCIekfJcUrX4gD/AJkXElpA0Yx0RKY3FVSytTLqnxwVrHmRd/DVudN1nGTxpDc4f2OgVvnTKtCzLf5GQPGZPoufzC0nKGgGEnf+JWznPKNN8AYhsWjfOZ97AvTvcNO++cIuaOHW9+EV+UtJY4NqWkDjBUGR5A574Oa5rRUkQ8hHFdGizY2OKaRrOOTTdm2yIhoehdHqvdhkNmwxa2e0xJ8o0WytMZys9PQiYxhGGrHZFE5S4bJ2RuLps1ysWNxIJjxJK5ldZko0WMZjoieySveHR87fsVNW/Kl7mWmriceKU1ak48Upq4nHilNUzJx4rXKBF3VqTjxklNUzJx2Rkl3VMyceMkpqmZOOyMkIJ+mP3Io+nd93VEJJvXZQ78OCXrsod+HBReuyhXz4cFN67KHvBAL12UPeCXpCUPeCi9dlCvsJek2UK+wgJvSEoJekJEYqCdKQkRX2F86+LPirKbPK32Vm4WbGaIk1pc6LQdJxcDtlDYvE5qCyzzJpH0W9qiRFTyRxiICWjU8F84zZ/wCoFqCG27Wvbi+yGi8byI6LuEl3H1bMoyZzrFwcCx0C3HVgWkVB3FQrYyTaCknwcznLKRaWhc0QEhvMBDSO8rVRYHZYwGBePKfRZEm5NtnCNdlj8sW37IzovDLRrhFpBG5e1B5lFxeGtwunzLYOZZa38jpAbAQP6iqnMuSadppG6yB4nAd10yvaSr/t/R0qj/QiIr52PL2AiBAIOBmFS5xzPAF9nxLf/wA/0rxFysqjNYZ5cVLk5LILQtcSK6JAIwjKPpFZVlylrRaP0aFx9cYboxWjnC1LLNzhWQ4RMI81gWNyl054eDU0tX469+XuYcszo1h0QNJwrAyHE7VpDPT4zY2G6MfWK08jyYvfoiWJOwK2OZ2Qq6O2I6QXRquOzO2ZM1bfPLnNg1uiTjGJ8pBaubsmL7QbAQSd2zzVkzMzIzc4jYIBWNjZNYNFoAG7vtXl2RisRJw3yZrNmk4N2kD1MF1tNXE4rms2WcbVo3x9BHqulpqmpxWh4dHEXLuylq5eZImmqanHilNUzJx4qKapmTjxU01TMmh4rRKgpqmZOPGSi7qmZNDsjJTTVMyaHjJRd1TMmh2RkhBP07vu6qFP07vu6qEJF67qwrhXhwS9d1YVw6Jeu6sK4dEvXdWFcOiAXrsoVw6Jek2UK+wpvXZQrh0S9JsoVw6ICKybIivsLRy7NNhbkadkxzmiGk9o0obA4Tgt6smyIrh0WrnHONnZM0nuDQJbydjQJkqJYx5uCYxcn0pZZw/xL8Eta11pkodIEusyS4wFTZkzPhMY4bDQfCme35NbCBJs3kB7Rs+8bxzEti6jOPxq90rFgYPufNx8hIepXJPMXF0ouJcYAARJiTASWfZKKeYGlR4NZOSlPZf6b+dc4/Me4taWMJk2M/PrCgVevSLifR1Uwqj0wWEerK1c0xaYH3Iq9yTKQ9sRIio2H+lQLLktuWPDsKEbQvLWSh4loI6ityivMuPc+h/D7f8AkTteegVqqT4btQWvbvDhwIh2Cu1p6d5rR8tHZBERdyQsGWW2hZk40HErOqjO9rFwbsmeJ/XVV9Tb+Otv+/w60w6pJFcoc0EQIiDUGilYcoypjLzgN1T6BfPJN8GserGwYy60CNYLItJudbImpHEGHJY8szowNIYYuIgIUG+K99E290MosA4bVK5vNTXG1bDCJJ3Yx94rpFFkOl4yE8lpmJkXOOMNEHeTHtzV5TVN44/tV+ZmgWe9xJB5DpzVhTVN44/uq3tJDopS+zLvl1WMmmqZuOKikjNxoeKU1TNxof3VKapm40PHfVWDiKSM3Gh2RolNUzJodkZBKSM3Gh2RpOqUkZuNDsjITQgn5Dvu5lQp+Q77uZRCSL13VhXDhRL13VhXDol67qwrhwol67qwrh0QgXrurCuHRTek2RFcOii9d1YVwj6JeuyIrhH0QAmMhIiuEfRfLPiHL3W2UvcbrSWtGAa0wjxJETx3BfUzOQkRXCPovkGXWRbavaate5vo4hVNU3hI2fBoxdkm+UtjCiIqR9GEReSUB6ReV6Qg6r4NyjWDdzmf/YdILs187+HLTRdpbHtP98l9EV7SSzFrsz43WQUdTOK75CIitlYgmE1zdtaaTi7aYq6zlaaNmd+r/fJUSyPEbMyUO25f0kNnI1svynQsy4VMhxK52zY974CLnGZj1JXSZZkotG6JMJxBGBWPIMibZgwMSaky8gFThNRj7lpptlW/M9oBLRO4H+wFFnmm0JmA3iQekV0CJ+aRPSjXyPJG2bYCZNSan9LZaImAqZKFuZrstK0GENaPCnOC8QTnNLuyJtRi32OhsmBrQzEAAH91XukjewP7qvLHAiAMT9w/uq9U1TewP7qvpI4xtwY7zncU1TNxof3VKSM3Gh6TqlJGbjQ9J1SkjNxoek6qSBSRm40OyNJ1QykZuNDsjITrVKSM3Gh2RpOqU1XTcaGsIyEzOqAn5Lvu5lE+S/7uZRAReu6sK4cKJeu6sK4cKJeu6sK4cKJeuyhXDhRAL13VhXCPol67IiuEfRTeuyhXDoovXZEVw6IBWTZEVwj6KlyzJWvBa9ocIm9t2g1B3hXRMZNkRXDoq20GseJ6qnq+EWdO2m2jkMt+FXRjZOBH22kiODgJ+YC0G/DmUEw0AN5cIciSu7RUcs1Y666Kxs/k5vN/wu0a1q7SP2tiG+Zq7kr+yyZjBBrWtGxrQByWVEyV7Lp2PMmV2W5lsbQXQ133MAafOEj5rmcr+G7dh1YPG1pAPmCehK7dEydKtVZXsnldmcpmnM9qGkObokn+RFIborrRaOgATQAGGJhVeUUqUo5w+SrOKnY7JcsLI20I38f7WNFMbJxeUw4RlyjXzlpPLQ0GAj6n/Oa1bPI3GshzVki52Lrk5S5PUX0x6UY7PJ2toPMzK9OswagHiF6RRhDLNK2yLFphuNPIrB9K/wC3mFaIvLriz2ptGjZZCf5GG4V9Vt2dm1tBBe0XqMVHg8uTfJvZGRowhrEmB/az0kb2B/dViyUjRAhMxgfPastNU3sD+6raqWIL4Rnz9TFJGbjQ9J1SkjNxoek6qaapvYHpNRSRm40PSa9nkUkZuNDsjSdUpqum40NYRkJmdUpqmbjQ7Nk0pIzcaGsI0nxQgn5L/u5lE+U/7uZRCSL12UK4cKJeuyhXDhRTeuy24cO6XrstuHBAReuyhXBL12RFcFNbktuCVuyOOCAiMZNkRXBV1vedxVjW7IiuCr8pvmG7pNVNWvKvk70epmJERZ5aCIiAIiIAiIgCIiAIiIAiIgCIiAIiIQWVhDQA/kRI8Z1Xvcb2B/a82UNED+UBA+Upr1uN7A/tbMFiK+ChLlimqb2B6TU0kbxoek1FJG9gek0pI3sD0mvRApIzcaHpNKSdNxodmyfFKSM3Gh6TSkjNxoek+KEE/Kf93MqE+W/7uaIBW5Lbhw7pW5LbhwStyW3Dh3StyW3DghJNbktuCVuyOOCVuS24JW7I44ICK3ZHHBaGVw05bB64qwrdkcVo5ZDSENk+MSq+qX6/s60+o10RFmFwIiIAiIgCIiAIiIAiIgCIiAIiIAiKQERBZtEBom9gek1O43sD0mm43sD+03G9gek1tozxuN7A9JpSRvYHpNNxvYHom43sD0QCknXsD0mlJOvGh6T4pSTr2B6c0pJ17A9OaEE6D9vNE0H7eaISRW5Lb27pW5Lb2StyW3tXzStyW3tVAK3JbVNbsjiorclt9lTW7XH2UArdkcVp5dCIhsMeK3K3a4+ytTLYShWcVw1K/WzpV6kai8l7do9QvRVcbB32lZZdN/5jfuHqE+Y37h6hV/yXfaU+S77SgLAWjfuHqF6Vd8h32lb7BAAHYgPSIiAIiIAiIgCIiAIiIAvTBFwG8dV5WSwB0hCsV6gsySIlwyx3G9gU3G9geibjewU7jew7LZM8jcb2B6JuN7A9FO43sOyjc69h2QDc69h25pudew7c03OvYduabnXsO3NCCdB+3miaNpt6IhJFbnn2r5pW559qqfB59q+aeDz7V80A8FcfZTwVx9lPBXH2U8FcfZQDwVx9la2W6OiIVjP0Wz4K4+ytfLNHRlWIiuV6zWz1X6kaKxm3Z93VZCFoHJXbvVZJfNv6hv3cin1Dfu5Fan0rtnMJ9K7ZzCA2/qG/dyKC3Z93Van0rtnMIMldsHqgN9FDRAAKUAREQBERAEREAREQBZcnB0xCs+ixLNkl+VYGHFdKlma+UeJ+llhxv4e6Jxv4dtycb+Huicb+Hbctcojjfw7bk8V/DtuTjfw7bk8V/DtuQDxX8O26qjxXsO3NPFew7UlVPFew7UlVCCdG029ESFp70UQkeDz7V808Hn2r5qPB59q+aeDz7V80BPgrj7KeCuPsp4K4+yngrj7KAjwVx9lYsqA0DCso+u/esvgrj7KxW4GiYVhP2d+xeLFmL+Geo+pFesJypu/0WYhaZyQ4EecVjl8y/VN3+ifVN3+iw/Ru2jn/AEn0bto5/wBIDN9U3f6J9U3f6LD9G7aOf9J9G7aOf9IDOMqbv81mWm3JDiR5RW4EBhdlTQYT8lLMoaTDqsD8kMZEQ3qbPJSCCSJTkgNtERAEREAREQBbGRXpVgYcZfta62ciqdsJcV1oWbEc7PSzc438O25Txv4dtyjjfw7blPG/h23LWKQ438O25QPyv4dqSQflfw7Ukg/K/h2pJAPFew7UlVPFew7UlVPFew7UlVPFew7UlVCCf+nvRRP+nvRRCR4PPtXzTwefavmh/Dz7V80P4efaqAeCuPsp4K4+yh/CuPsofwrj7KAeCuPsry9oIIbUyPsr0fwrj7KeCuPsoCqc2BgcFCsLewDhq1x9laT7Miqy7aZQey2LkLFJe54REXA6hERAEREAREQBERAEREARF6aCTAIlngHlb2SWYAj/ACMxw6LHZZLtrg3+zRbY33/flRXtNS4vql9FW2xNdKHG/h23KeN/DtuTjfw90Tjfw7bldOA438O25QPyv4dqSU8b+Hbcg338O25AR4r2Hakqp4r2Hakqp4r2Hakqp4r2HakqoQT/ANPeiif9PeiiEn//2Q==",
                  name: searchText,
                  isChecked: false);
              items.add(p);
            }
            if (searchText == '') {
              showAlertDialog(context);
            }
          });
          searchText = "";
          _controller.clear();
        },
      );

  Widget _footerButtons() {
    return Container(
        color: Colors.green.shade500,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SizedBox(width: 120, child: _buildButtonSaveGroceryList()),
            SizedBox(
              width: 120,
              child: _buildButtonLoadGroceryList(),
            ),
            SizedBox(width: 120, child: _buildButtonDeleteStorage()),
          ],
        ));
  }

  Widget _buildButtonSaveGroceryList() => ElevatedButton(
        child: const Text(
          "Sauvegarder",
          style: TextStyle(fontSize: 14),
          textAlign: TextAlign.center,
        ),
        style: ElevatedButton.styleFrom(
          primary: Colors.green.shade300,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        ),
        onPressed: () async {
          for (var item in items) {
            save1.add(item);
            await DAO.writeProduct(item);
            Storage.addAndStoreProduct(item);
          }
          showAlertDialogSaveList(context);
        },
      );

  Widget _buildButtonLoadGroceryList() => ElevatedButton(
      child: const Text(
        "Restaurer",
        style: TextStyle(fontSize: 14),
        textAlign: TextAlign.center,
      ),
      style: ElevatedButton.styleFrom(
        primary: Colors.green.shade300,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      ),
      onPressed: () {
        setState(() {
          Storage.printProducts(items);
        });
      });

  Widget _buildButtonDeleteStorage() => ElevatedButton(
      child: const Text(
        "Supprimer",
        style: TextStyle(fontSize: 14),
        textAlign: TextAlign.center,
      ),
      style: ElevatedButton.styleFrom(
        primary: Colors.red.shade500,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      ),
      onPressed: () {
        setState(() {
          Storage.clearProducts();
        });
      });

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double animValue = Curves.easeInOut.transform(animation.value);
        final double elevation = lerpDouble(0, 6, animValue)!;
        return Material(
          elevation: elevation,
          color: Colors.amber.shade200,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          child: child,
        );
      },
      child: child,
    );
  }

  showAlertDialog(BuildContext context) {
    // set up the buttons
    // Widget cancelButton = TextButton(
    //   child: const Text("Annuler"),
    //   onPressed: () {},
    // );
    Widget continueButton = TextButton(
      child: const Text("Continuer"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Attention"),
      content: const Text("Tout produit a un nom !"),
      actions: [
        //cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  showAlertDialogSaveList(BuildContext context) {
    Widget continueButton = TextButton(
      child: const Text("OK"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Information"),
      content: const Text("Liste sauvegardée"),
      actions: [
        //cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
