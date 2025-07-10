import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gestao_leitores/screens/escala_liturgica_view.dart';
import 'firebase_options.dart'; // gerado pelo flutterfire configure

void main() async {
  // Garante que o Flutter esteja pronto antes de inicializações assíncronas
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase com as opções corretas para a plataforma atual
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true, // Habilita o cache offline
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const GestaoLeitoresApp());
}

class GestaoLeitoresApp extends StatelessWidget {
  const GestaoLeitoresApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.white,
      title: 'Gestão de Leitores',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF8F2F8),
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: Colors.white),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: EscalaLiturgicaView(),
    );
  }
}
