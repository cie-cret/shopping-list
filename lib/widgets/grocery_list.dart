import 'dart:convert';

import 'package:a4_shopping_list/data/categories.dart';
// import 'package:a4_shopping_list/models/category.dart';
import 'package:a4_shopping_list/models/grocery_item.dart';
import 'package:a4_shopping_list/widgets/new_item.dart';
import 'package:flutter/material.dart';
// import 'package:a4_shopping_list/data/dummy_items.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    await dotenv.load();
    final firebaseURL = dotenv.env['FIREBASE_URL'];

    final url = Uri.https(firebaseURL!, 'shopping-list.json');

    try {
      final response = await http.get(url);

      if (response.statusCode >= 400) {
        _isLoading = false;
        setState(() {
          _error = 'Failed to fetch data. Please try again later.';
        });
      }

      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];

      for (final item in listData.entries) {
        // entries = make {} to [] (make Map to List)
        final category = categories.entries
            .firstWhere((cat) => cat.value.title == item.value['category'])
            .value;
        // What is this again ???
        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }

      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });

      // print(response.body);
      // print(response.statusCode);
    } catch (error) {
      setState(() {
        _isLoading = false;
        _error = 'Something went wrong. Please try again later.';
      });
    }
  }

  void _addItem() async {
    // AGAIN?
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (context) {
          return const NewItem();
        },
      ),
    );

    // _loadItems();

    if (newItem == null) {
      // could be null if the user presses back button
      return;
    }

    setState(
      () {
        _groceryItems.add(newItem);
        // print(_groceryItems);
      },
    );
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);

    setState(() {
      _groceryItems.remove(item);
    });

    await dotenv.load();
    final firebaseURL = dotenv.env['FIREBASE_URL'];

    final url = Uri.https(firebaseURL!, 'shopping-list/${item.id}.json');

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
        // OK, remember here
      });
    }
  }

  void _editItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);

    if (index == -1) {
      // If the item doesn't exist in the list
      return;
    }

    final editedItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (context) {
          return NewItem(item: item);
        },
      ),
    );

    if (editedItem != null) {
      setState(() {
        _groceryItems[index] = editedItem;
      });
    } else if (editedItem == null) {
      return;
    }

    // await dotenv.load();
    // final firebaseURL = dotenv.env['FIREBASE_URL'];

    // final url = Uri.https(firebaseURL!, 'shopping-list/${item.id}.json');

    //     final Map<String, dynamic> resData = json.decode(response.body);
    //     Navigator.of(context).pop(
    //       GroceryItem(
    //           id: resData['name'],
    //           name: _enteredName,
    //           quantity: _enteredQuantity,
    //           category: _selectedCategory),
    //     );

    // final response = await http.delete(url);

    // if (response.statusCode >= 400) {
    //   setState(() {
    //     _groceryItems.insert(index, item);
    //     // OK, remember here
    //   });
    // }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text(
        'No Items Added Yet',
        style: TextStyle(
          fontSize: 24,
        ),
      ),
    );

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    } else if (_error != null) {
      content = Center(
        child: Text(_error!),
      );
    } else if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (context, index) {
          return Dismissible(
            key: ValueKey(_groceryItems[index].id),
            direction: DismissDirection.horizontal,
            onDismissed: (direction) {
              if (direction == DismissDirection.endToStart) {
                _removeItem(_groceryItems[index]);
              } else if (direction == DismissDirection.startToEnd) {
                _editItem(_groceryItems[index]);
              }
            },
            child: ListTile(
              title: Text(_groceryItems[index].name),
              leading: Container(
                width: 24,
                height: 24,
                color: _groceryItems[index].category.color,
              ),
              trailing: Text(
                _groceryItems[index].quantity.toString(),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery List'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: content,
    );
  }
}
