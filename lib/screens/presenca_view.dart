import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:gestao_leitores/models/escala_liturgica.dart';
import 'package:gestao_leitores/models/leitor.dart';
import 'package:gestao_leitores/models/presenca_model.dart';
import 'package:gestao_leitores/services/firestore_service.dart';

// >>> IMPORTA O TEU FORMULÁRIO AQUI (ajusta o path conforme a tua estrutura)
import 'package:gestao_leitores/screens/presenca_form.dart';

class PresencaView extends StatefulWidget {
  @override
  _PresencaViewState createState() => _PresencaViewState();
}

class _PresencaViewState extends State<PresencaView> {
  final FirestoreService _firestoreService = FirestoreService();

  List<PresencaModel> _presencas = [];
  List<EscalaLiturgica> _escalas = [];
  Map<String, Leitor> _leitores = {}; // Map para armazenar leitores por id

  @override
  void initState() {
    super.initState();
    _loadPresencas();
    _loadEscalas();
    _loadLeitores();
  }

  // Carregar as presenças do Firestore
  void _loadPresencas() {
    _firestoreService.getPresencas().listen((presencas) {
      setState(() {
        _presencas = presencas;
      });
    });
  }

  // Carregar escalas litúrgicas
  void _loadEscalas() {
    _firestoreService.getEscalasLiturgicas().listen((escalas) {
      setState(() {
        _escalas = escalas;
      });
    });
  }

  // Carregar leitores
  void _loadLeitores() {
    _firestoreService.getLeitores().listen((leitores) {
      setState(() {
        _leitores = {for (var leitor in leitores) leitor.id: leitor};
      });
    });
  }

  // Formatação da data
  String _formatData(DateTime data) {
    return DateFormat('dd/MM/yyyy').format(data);
  }

  // Encontrar o nome do Leitor
  String _getLeitorNome(String leitorId) {
    print('Buscando nome do leitor com ID: $leitorId');
    return _leitores[leitorId]?.nome ?? 'Leitor Desconhecido';
  }

  // Encontrar o Domingo da Escala
  String _getEscalaDomingo(String escalaId) {
    final escala = _escalas.firstWhere(
      (escala) => escala.id == escalaId,
      orElse: () => EscalaLiturgica(
        id: '',
        domingo: 'Domingo Desconhecido',
        data: '',
        introdutorId: '',
        primeiraLeituraLLId: '',
        primeiraLeituraPTId: '',
        segundaLeituraLLId: '',
        segundaLeituraPTId: '',
        evangelhoId: '',
      ),
    );
   return escala.domingo;
  }

  // Agrupar as presenças por Leitor
  Map<String, List<PresencaModel>> _groupPresencasByLeitor() {
    final Map<String, List<PresencaModel>> groupedPresencas = {};
    for (var presenca in _presencas) {
      final leitorId = presenca.leitorId;
      groupedPresencas.putIfAbsent(leitorId, () => []);
      groupedPresencas[leitorId]!.add(presenca);
    }
    return groupedPresencas;
  }

  // Visualizar detalhes de uma presença
  void _viewPresencaDetails(PresencaModel presenca) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Detalhes da Presença'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Leitor: ${_getLeitorNome(presenca.leitorId)}'),
              Text('Escala: ${_getEscalaDomingo(presenca.escalaId)}'),
              Text('Data: ${_formatData(presenca.data)}'),
              Text('Presente na Missa: ${presenca.presenteMissa ? 'Sim' : 'Não'}'),
              Text('Presente no Ensaio: ${presenca.presenteEnsaio ? 'Sim' : 'Não'}'),
              if (presenca.presenteMissa) ...[
                Text('Dicção: ${presenca.diccao}'),
                Text('Colocação de Voz: ${presenca.colocacaoVoz}'),
                Text('Sinais de Pontuação: ${presenca.sinaisPontuacao}'),
                Text('Ritmo: ${presenca.ritmo}'),
              ],
              Text('Observação: ${presenca.observacao}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  // Navegar para o formulário em modo edição
  Future<void> _editPresenca(PresencaModel presenca) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PresencaForm(presenca: presenca),
      ),
    );
    // Streams já actualizam a lista, mas se quiser forçar:
    // _loadPresencas();
  }

  @override
  Widget build(BuildContext context) {
    final groupedPresencas = _groupPresencasByLeitor();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presenças Registradas'),
        backgroundColor: Colors.teal.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _presencas.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: groupedPresencas.keys.length,
                itemBuilder: (context, index) {
                  final leitorId = groupedPresencas.keys.elementAt(index);
                  final leitorPresencas = groupedPresencas[leitorId]!;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ExpansionTile(
                      title: Text('Leitor: ${_getLeitorNome(leitorId)}'),
                      children: leitorPresencas.map((presenca) {
                        return ListTile(
                          title: Text('Escala: ${_getEscalaDomingo(presenca.escalaId)}'),
                          subtitle: Text('Data: ${_formatData(presenca.data)}'),
                          onTap: () => _viewPresencaDetails(presenca),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Editar',
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editPresenca(presenca),
                              ),
                              IconButton(
                                tooltip: 'Mais detalhes',
                                icon: const Icon(Icons.more_vert),
                                onPressed: () => _viewPresencaDetails(presenca),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
