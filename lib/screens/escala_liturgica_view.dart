import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../models/escala_liturgica.dart';
import '../models/leitor.dart';
import '../services/firestore_service.dart';
import 'escala_form.dart';

class EscalaLiturgicaView extends StatefulWidget {
  const EscalaLiturgicaView({super.key});

  @override
  State<EscalaLiturgicaView> createState() => _EscalaLiturgicaViewState();
}

class _EscalaLiturgicaViewState extends State<EscalaLiturgicaView> {
  final FirestoreService _service = FirestoreService();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_PT', null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Escalas Litúrgicas"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nova Escala',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EscalaForm()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<EscalaLiturgica>>(
        stream: _service.getEscalasLiturgicas(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final escalas = snapshot.data!;

          if (escalas.isEmpty) {
            return const Center(child: Text("Nenhuma escala registrada."));
          }

          return ListView.builder(
            itemCount: escalas.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final escala = escalas[index];
              return FutureBuilder<Map<String, Leitor>>(
                future: _buscarLeitoresDaEscala(escala),
                builder: (context, leitorSnapshot) {
                  if (!leitorSnapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final leitores = leitorSnapshot.data!;
                  return Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Cabeçalho ──
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                size: 32,
                                color: Colors.teal,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      escala.domingo,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      _formatarData(escala.data),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.indigo,
                                    ),
                                    tooltip: 'Editar escala',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => EscalaForm(escala: escala),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Excluir escala',
                                    onPressed: () => _confirmarExclusao(escala),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),

                          // ── Lista de Leitores (1 por linha) ──
                          _leitorLinha(
                            "Introdutor",
                            leitores[escala.introdutorId],
                          ),
                          _leitorLinha(
                            "1ª Leitura (Língua Local)",
                            leitores[escala.primeiraLeituraLLId],
                          ),
                          _leitorLinha(
                            "1ª Leitura (Português)",
                            leitores[escala.primeiraLeituraPTId],
                          ),
                          _leitorLinha(
                            "2ª Leitura (Língua Local)",
                            leitores[escala.segundaLeituraLLId],
                          ),
                          _leitorLinha(
                            "2ª Leitura (Português)",
                            leitores[escala.segundaLeituraPTId],
                          ),
                          _leitorLinha(
                            "Evangelho",
                            leitores[escala.evangelhoId],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmarExclusao(EscalaLiturgica escala) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Excluir Escala'),
            content: const Text('Tem certeza que deseja excluir esta escala?'),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      await _service.deleteEscalaLiturgica(escala.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Escala excluída com sucesso')),
        );
      }
    }
  }

  Future<Map<String, Leitor>> _buscarLeitoresDaEscala(
    EscalaLiturgica escala,
  ) async {
    final ids = {
      escala.introdutorId,
      escala.primeiraLeituraLLId,
      escala.primeiraLeituraPTId,
      escala.segundaLeituraLLId,
      escala.segundaLeituraPTId,
      escala.evangelhoId,
    };
    final leitores = await _service.getLeitoresByIds(ids.toList());
    return {for (var l in leitores) l.id: l};
  }

  Widget _linha(String titulo, String? nome) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "🔸 $titulo:",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(nome ?? 'Desconhecido'),
        ],
      ),
    );
  }

  String _formatarData(String isoDate) {
    final data = DateTime.tryParse(isoDate);
    if (data == null) return isoDate;
    return DateFormat("EEEE, dd 'de' MMMM", 'pt_PT').format(data);
  }

  Widget _leitorLinha(String funcao, Leitor? leitor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            funcao,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 2),
          Text(leitor?.nome ?? '—', style: const TextStyle(fontSize: 15)),
          Text(
            leitor?.contacto ?? '',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
