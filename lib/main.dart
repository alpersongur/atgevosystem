import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'customers/customer_form_page.dart';
import 'customers/customer_list_page.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ATG CRM',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      initialRoute: CustomersListPage.routeName,
      routes: {
        CustomersListPage.routeName: (context) => const CustomersListPage(),
        CustomerFormPage.routeName: (context) => const CustomerFormPage(),
      },
    );
  }
}
