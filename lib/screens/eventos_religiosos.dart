import 'package:flutter/material.dart';
import 'package:gestao_leitores/models/evento_religioso.dart';
import 'package:gestao_leitores/models/usuarios.dart';
import 'package:gestao_leitores/services/firestore_service.dart';
import 'package:intl/intl.dart';

class EventosReligiososScreen extends StatefulWidget {
  final Usuario? usuario;

  const EventosReligiososScreen({super.key, this.usuario});

  @override
  State<EventosReligiososScreen> createState() => _EventosReligiososScreenState();
}

class _EventosReligiososScreenState extends State<EventosReligiososScreen> {
  final FirestoreService _service = FirestoreService();
  late Future<List<EventoReligioso>> _eventosFuture;

  @override
  void initState() {
    super.initState();
    _carregarEventos();
  }

  void _carregarEventos() {
    _eventosFuture = _service.getEventosReligiosos();
  }

  void _mostrarFormulario({EventoReligioso? eventoExistente}) {
    final _tituloController = TextEditingController(text: eventoExistente?.titulo);
    final _obsController = TextEditingController(text: eventoExistente?.observacao);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(eventoExistente == null ? 'Novo Evento' : 'Editar Evento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _tituloController,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              TextField(
                controller: _obsController,
                decoration: const InputDecoration(labelText: 'Observação'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final titulo = _tituloController.text.trim();
                final obs = _obsController.text.trim();

                if (titulo.isEmpty) return;

                if (eventoExistente == null) {
                  final novoEvento = EventoReligioso(
                    id: '',
                    titulo: titulo,
                    observacao: obs,
                    criadoEm: DateTime.now(),
                  );
                  await _service.criarEventoReligioso(novoEvento);
                } else {
                  await _service.atualizarEventoReligioso(eventoExistente.id, {
                    'titulo': titulo,
                    'observacao': obs,
                  });
                }

                Navigator.pop(context);
                _carregarEventos();
                setState(() {});
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmarExclusao(EventoReligioso evento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Evento'),
        content: const Text('Deseja realmente excluir este evento?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmar == true) {
      await _service.deletarEventoReligioso(evento.id);
      _carregarEventos();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos Religiosos'),
        actions: [
          if (widget.usuario != null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _mostrarFormulario(),
              tooltip: 'Novo Evento',
            ),
        ],
      ),
      body: FutureBuilder<List<EventoReligioso>>(
        future: _eventosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma atividade religiosa registrada.'));
          }

          final eventos = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: eventos.length,
            itemBuilder: (context, index) {
              final evento = eventos[index];
              return Card(
  margin: const EdgeInsets.symmetric(vertical: 8),
  child: Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          evento.titulo,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          evento.observacao,
          style: const TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('dd/MM/yyyy').format(evento.criadoEm),
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            if (widget.usuario != null)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.indigo),
                    tooltip: 'Editar',
                    onPressed: () => _mostrarFormulario(eventoExistente: evento),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Excluir',
                    onPressed: () => _confirmarExclusao(evento),
                  ),
                ],
              ),
          ],
        ),
      ],
    ),
  ),
);

            },
          );
        },
      ),
    );
  }
}
