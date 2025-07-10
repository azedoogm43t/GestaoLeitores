import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/leitor.dart';
import 'leitor_form.dart';

class LeitoresPage extends StatelessWidget {
  const LeitoresPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leitores cadastrados'),
        backgroundColor: Colors.teal.shade700,
      ),
      body: StreamBuilder<List<Leitor>>(
        stream: service.getLeitores(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final leitores = snapshot.data ?? [];

          if (leitores.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum leitor encontrado.',
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: leitores.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final leitor = leitores[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: leitor.ativo
                        ? Colors.green.shade300
                        : Colors.red.shade300,
                    child: Icon(
                      leitor.ativo ? Icons.check : Icons.close,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    leitor.nome,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(leitor.contacto),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.teal),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LeitorForm(leitor: leitor),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.person_add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LeitorForm()),
        ),
      ),
    );
  }
}
