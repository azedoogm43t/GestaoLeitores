import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/leitor.dart';
import 'leitor_form.dart';

class LeitoresPage extends StatefulWidget {
  const LeitoresPage({Key? key}) : super(key: key);

  @override
  State<LeitoresPage> createState() => _LeitoresPageState();
}

class _LeitoresPageState extends State<LeitoresPage> {
  final service = FirestoreService();
  String filtro = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leitores cadastrados'),
        backgroundColor: Colors.teal.shade700,
      ),
      body: Column(
        children: [
          // 🔍 Barra de pesquisa
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Pesquisar por nome ou contacto...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) {
                setState(() {
                  filtro = value.toLowerCase().trim();
                });
              },
            ),
          ),

          // 🔄 Lista de leitores com filtro e ordenação
          Expanded(
            child: StreamBuilder<List<Leitor>>(
              stream: service.getLeitores(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }

                List<Leitor> leitores = snapshot.data ?? [];

                // 🔠 Ordenar alfabeticamente
                leitores.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));

                // 🔍 Aplicar filtro
                if (filtro.isNotEmpty) {
                  leitores = leitores.where((leitor) {
                    final nome = leitor.nome.toLowerCase();
                    final contacto = leitor.contacto.toLowerCase();
                    return nome.contains(filtro) || contacto.contains(filtro);
                  }).toList();
                }

                if (leitores.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum leitor encontrado.',
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
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
                      ),
                    ),

                     // -------- Footer --------
                    Column(
                      children: const [
                        Divider(),
                        SizedBox(height: 6),
                        Text(
                          'Desenvolvido por Dênis & Januário',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          'Contacto: +258 82 489 2424',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        SizedBox(height: 12),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
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
