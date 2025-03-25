import 'dart:convert';

import 'package:a4_shopping_list/data/categories.dart';
import 'package:a4_shopping_list/models/category.dart';
import 'package:a4_shopping_list/models/grocery_item.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class NewItem extends StatefulWidget {
  const NewItem({super.key, this.item, required this.firebaseURL});
  final String firebaseURL;

  final GroceryItem? item;

  @override
  State<NewItem> createState() {
    return _NewItem();
  }
}

class _NewItem extends State<NewItem> {
  // void _addItem(BuildContext context) {
  //   Navigator.of(context).push(MaterialPageRoute(builder: (context) {
  //     return const NewItem();
  //   }));
  // }

  final _formKey = GlobalKey<FormState>();
  // What is it again?
  // var _enteredName = '';
  final TextEditingController _enteredName = TextEditingController();
  var _enteredQuantity = 1;
  var _selectedCategory = categories[Categories.vegetables]!;
  var _isSending = false;
  var _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.item != null;

    if (widget.item != null) {
      // If item is passed (editing mode)
      _enteredName.text = widget.item!.name;
      _enteredQuantity = widget.item!.quantity;
      _selectedCategory = widget.item!.category;
    } else {
      _enteredName.text = '';
      _enteredQuantity = 1;
      _selectedCategory = categories.entries.first.value; // Default category
    }
  }

  void _saveItem() async {
    final firebaseURL = widget.firebaseURL;
    if (_formKey.currentState!.validate()) {
      // Exclaimation mark is null-safety, make sure it's not null
      _formKey.currentState!.save();
      setState(() {
        _isSending = true;
      });

      final url = _isEditing
          ? Uri.https(firebaseURL, 'shopping-list/${widget.item!.id}.json')
          : Uri.https(firebaseURL, 'shopping-list.json');

      try {
        if (_isEditing) {
          await http.patch(
            url,
            body: json.encode(
              {
                'name': _enteredName.text,
                'quantity': _enteredQuantity,
                'category': _selectedCategory.title,
              },
            ),
          );

          if (!mounted) {
            return;
          }

          Navigator.of(context).pop(
            GroceryItem(
                id: widget.item!.id,
                name: _enteredName.text,
                quantity: _enteredQuantity,
                category: _selectedCategory),
          );
        } else {
          final response = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              // Make Firebase understand how the data we're sending is gonna be formatted
            },
            body: json.encode(
              {
                'name': _enteredName.text,
                'quantity': _enteredQuantity,
                'category': _selectedCategory.title,
              },
            ),
          );

          if (!mounted) return;
          // Navigator.of(context).pop();

          // Update new added item in local storage
          final Map<String, dynamic> resData = json.decode(response.body);
          Navigator.of(context).pop(
            GroceryItem(
                id: resData['name'],
                name: _enteredName.text,
                quantity: _enteredQuantity,
                category: _selectedCategory),
          );
        }
      } catch (error) {
        setState(() {
          _isSending = false;

          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Error'),
              content: const Text('Something went wrong. Please try again.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        });
      }
    }
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        title:
            _isEditing ? const Text('Edit item') : const Text('Add a new item'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _enteredName,
                maxLength: 50,
                decoration: const InputDecoration(
                  label: Text('Name'),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      value.trim().length <= 1 ||
                      value.trim().length > 50) {
                    return 'Must be between 1 and 50 characters.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _enteredName.text = value!;
                },
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        label: Text('Quantity'),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: _enteredQuantity.toString(),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            int.tryParse(value) == null ||
                            int.tryParse(value)! <= 0) {
                          return 'Please enter positive number';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _enteredQuantity = int.parse(value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField(
                      value: _selectedCategory,
                      items: [
                        for (final category in categories.entries)
                          DropdownMenuItem(
                            value: category.value,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  color: category.value.color,
                                ),
                                const SizedBox(width: 8),
                                Text(category.value.title),
                              ],
                            ),
                          )
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                          // Make it reflect on screen bc value: _selectedCategory
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 12,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSending
                        ? null
                        : () {
                            _formKey.currentState!.reset();
                            _enteredName.clear();

                            setState(() {
                              _enteredQuantity = 1;
                              _selectedCategory =
                                  categories[Categories.vegetables]!;
                            });
                          },
                    child: const Text(
                      'Reset',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: _isSending ? null : _saveItem,
                    child: _isSending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator())
                        : _isEditing
                            ? const Text('Update')
                            : const Text('Add'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
