import 'package:a4_shopping_list/widgets/grocery_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load();
  final firebaseURL = dotenv.env['FIREBASE_URL'] ?? '';
  runApp(MyApp(
    firebaseURL: firebaseURL,
  ));
}

class MyApp extends StatelessWidget {
  final String firebaseURL;

  const MyApp({super.key, required this.firebaseURL});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Groceries',
      theme: ThemeData.dark().copyWith(
        // useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 147, 229, 250),
          brightness: Brightness.dark,
          surface: const Color.fromARGB(255, 42, 51, 59),
        ),
        scaffoldBackgroundColor: const Color.fromARGB(255, 50, 58, 60),
      ),
      home: GroceryList(
        firebaseURL: firebaseURL,
      ),
    );
  }
}
