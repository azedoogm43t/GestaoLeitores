import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:gestao_leitores/models/usuarios.dart';
import 'package:gestao_leitores/screens/eventos_religiosos.dart';
import 'package:gestao_leitores/screens/login_form.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../models/escala_liturgica.dart';
import '../models/leitor.dart';
import '../services/firestore_service.dart';
import 'escala_form.dart';

class EscalaLiturgicaView extends StatefulWidget {
  final Usuario? usuario;

  const EscalaLiturgicaView({super.key, this.usuario});

  @override
  State<EscalaLiturgicaView> createState() => _EscalaLiturgicaViewState();
}

class _EscalaLiturgicaViewState extends State<EscalaLiturgicaView> {
  final FirestoreService _service = FirestoreService();
  final _searchController = TextEditingController();
  List<EscalaLiturgica> _todasEscalas = [];
  List<EscalaLiturgica> _escalasFiltradas = [];
  bool _buscando = false;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_PT', null);
    _verificarConectividade();
  }

  void _verificarConectividade() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _offline = connectivityResult == ConnectivityResult.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Escalas"),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            label: const Text('Eventos', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EventosReligiososScreen(usuario: widget.usuario),
                ),
              );
            },
          ),
          if (widget.usuario == null)
            TextButton.icon(
              icon: const Icon(Icons.login, color: Colors.white),
              label: const Text('Login', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Nova Escala',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => EscalaForm(usuario: widget.usuario)),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (_offline)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Você está offline. Mostrando escalas salvas no cache.',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Buscar por nome do leitor',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _filtrarEscalasPorNome,
                  child: const Text("Buscar"),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Limpar filtro',
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _buscando = false;
                    });
                  },
                )
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<EscalaLiturgica>>(
              stream: _service.getEscalasLiturgicas(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                _todasEscalas = snapshot.data!;
                _escalasFiltradas =
                    _buscando ? _escalasFiltradas : _todasEscalas;

                if (_escalasFiltradas.isEmpty) {
                  return const Center(
                      child: Text("Nenhuma escala encontrada."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _escalasFiltradas.length,
                  itemBuilder: (context, index) {
                    final escala = _escalasFiltradas[index];
                    return FutureBuilder<Map<String, Leitor>>(
                      future: _buscarLeitoresDaEscala(escala),
                      builder: (context, snapshotLeitores) {
                        if (!snapshotLeitores.hasData) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final leitores = snapshotLeitores.data!;
                        return _buildCard(escala, leitores);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, Leitor>> _buscarLeitoresDaEscala(
      EscalaLiturgica escala) async {
    final ids = {
      escala.introdutorId,
      escala.primeiraLeituraLLId,
      escala.primeiraLeituraPTId,
      escala.segundaLeituraLLId,
      escala.segundaLeituraPTId,
      escala.evangelhoId,
    }.where((id) => id.trim().isNotEmpty).toList();

    final leitores = await _service.getLeitoresByIds(ids);
    return {for (var leitor in leitores) leitor.id: leitor};
  }

  Future<void> _filtrarEscalasPorNome() async {
    final nomeBuscado = _searchController.text.trim().toLowerCase();
    if (nomeBuscado.isEmpty) {
      setState(() {
        _buscando = false;
      });
      return;
    }

    List<EscalaLiturgica> resultados = [];

    for (final escala in _todasEscalas) {
      final ids = {
        escala.introdutorId,
        escala.primeiraLeituraLLId,
        escala.primeiraLeituraPTId,
        escala.segundaLeituraLLId,
        escala.segundaLeituraPTId,
        escala.evangelhoId,
      }.where((id) => id.trim().isNotEmpty).toList();

      final leitores = await _service.getLeitoresByIds(ids);
      final leitorEncontrado = leitores
          .any((leitor) => leitor.nome.toLowerCase().contains(nomeBuscado));

      if (leitorEncontrado) {
        resultados.add(escala);
      }
    }

    setState(() {
      _escalasFiltradas = resultados;
      _buscando = true;
    });
  }

  Widget _buildCard(EscalaLiturgica escala, Map<String, Leitor> leitores) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.calendar_month_rounded,
                    size: 32, color: Colors.teal),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(escala.domingo,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      Text(_formatarData(escala.data),
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ),
                if (widget.usuario != null)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.indigo),
                        tooltip: 'Editar escala',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => EscalaForm(
                                    escala: escala, usuario: widget.usuario)),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: Colors.red),
                        tooltip: 'Excluir escala',
                        onPressed: () => _confirmarExclusao(escala),
                      ),
                    ],
                  )
              ],
            ),
            const Divider(height: 24),
            _leitorLinhaCond("Introdutor", escala.introdutorId, leitores),
            _leitorLinhaCond("1ª Leitura (Língua Local)",
                escala.primeiraLeituraLLId, leitores),
            _leitorLinhaCond(
                "1ª Leitura (Português)", escala.primeiraLeituraPTId, leitores),
            _leitorLinhaCond("2ª Leitura (Língua Local)",
                escala.segundaLeituraLLId, leitores),
            _leitorLinhaCond(
                "2ª Leitura (Português)", escala.segundaLeituraPTId, leitores),
            _leitorLinhaCond("Evangelho", escala.evangelhoId, leitores),
          ],
        ),
      ),
    );
  }

  Widget _leitorLinhaCond(
      String label, String? id, Map<String, Leitor> leitores) {
    if (id == null || id.trim().isEmpty) return const SizedBox.shrink();

    final leitor = leitores[id];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.teal)),
          const SizedBox(height: 2),
          Text(leitor?.nome ?? '—', style: const TextStyle(fontSize: 15)),
            if (widget.usuario != null)
              if (leitor?.contacto != null && leitor!.contacto.trim().isNotEmpty)
                Text(leitor.contacto,
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }

  String _formatarData(String isoDate) {
    final data = DateTime.tryParse(isoDate);
    if (data == null) return isoDate;
    return DateFormat("EEEE, dd 'de' MMMM", 'pt_PT').format(data);
  }

  Future<void> _confirmarExclusao(EscalaLiturgica escala) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Escala'),
        content: const Text('Tem certeza que deseja excluir esta escala?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
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

  Future<bool> isOffline() async {
    final result = await Connectivity().checkConnectivity();
    return result == ConnectivityResult.none;
  }
}
