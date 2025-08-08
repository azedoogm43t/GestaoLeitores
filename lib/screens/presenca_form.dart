import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:gestao_leitores/models/escala_liturgica.dart';
import 'package:gestao_leitores/models/leitor.dart';
import 'package:gestao_leitores/models/presenca_model.dart';
import 'package:gestao_leitores/services/firestore_service.dart';

class PresencaForm extends StatefulWidget {
  final PresencaModel? presenca; // se vier preenchido, é edição

  const PresencaForm({Key? key, this.presenca}) : super(key: key);

  @override
  _PresencaFormState createState() => _PresencaFormState();
}

class _PresencaFormState extends State<PresencaForm> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  String? _escalaId;
  String? _leitorId;
  DateTime _data = DateTime.now();

  bool _presenteMissa = false;
  bool _presenteEnsaio = false;

  double _diccao = 0.0;
  double _colocacaoVoz = 0.0;
  double _sinaisPontuacao = 0.0;
  double _ritmo = 0.0;
  String _observacao = '';

  List<EscalaLiturgica> _escalasLiturgicas = [];
  List<Leitor> _leitores = [];
  List<Leitor> _leitoresFiltrados = [];

  late final TextEditingController _dataCtrl;

  @override
  void initState() {
    super.initState();
    _dataCtrl = TextEditingController();

    _loadEscalasLiturgicas();

    // Pré-carrega se for edição
    if (widget.presenca != null) {
      final p = widget.presenca!;
      _escalaId = p.escalaId;
      _leitorId = p.leitorId;
      _data = p.data;
      _presenteMissa = p.presenteMissa;
      _presenteEnsaio = p.presenteEnsaio;
      _diccao = p.diccao;
      _colocacaoVoz = p.colocacaoVoz;
      _sinaisPontuacao = p.sinaisPontuacao;
      _ritmo = p.ritmo;
      _observacao = p.observacao;
      _updateDataCtrl();
      _loadLeitores(); // carrega filtrados para a escala definida
    } else {
      _updateDataCtrl();
    }
  }

  @override
  void dispose() {
    _dataCtrl.dispose();
    super.dispose();
  }

  void _updateDataCtrl() {
    _dataCtrl.text = DateFormat('yyyy-MM-dd').format(_data);
  }

  // Carregar as escalas litúrgicas do Firestore
  void _loadEscalasLiturgicas() {
    _firestoreService.getEscalasLiturgicas().listen((escalas) {
      setState(() {
        _escalasLiturgicas = escalas;
      });
    });
  }

  // Carregar os leitores do Firestore e filtrar com base na escala selecionada
  void _loadLeitores() {
    _firestoreService.getLeitores().listen((leitores) {
      setState(() {
        _leitores = leitores;

        if (_escalaId != null && _escalaId!.isNotEmpty) {
          final escalaSelecionada = _escalasLiturgicas.firstWhere(
            (escala) => escala.id == _escalaId,
            orElse: () => EscalaLiturgica(
              id: '',
              domingo: '',
              data: DateFormat('yyyy-MM-dd').format(_data),
              introdutorId: '',
              primeiraLeituraLLId: '',
              primeiraLeituraPTId: '',
              segundaLeituraLLId: '',
              segundaLeituraPTId: '',
              evangelhoId: '',
            ),
          );

          final ids = <String>{
            escalaSelecionada.introdutorId,
            escalaSelecionada.primeiraLeituraLLId,
            escalaSelecionada.primeiraLeituraPTId,
            escalaSelecionada.segundaLeituraLLId,
            escalaSelecionada.segundaLeituraPTId,
            escalaSelecionada.evangelhoId,
          }..removeWhere((e) => e.isEmpty);

          _leitoresFiltrados = _leitores.where((l) => ids.contains(l.id)).toList();
        } else {
          _leitoresFiltrados = [];
        }
      });
    });
  }

  // Nome do leitor pelo ID (para mostrar no item sintético)
  String _nomeLeitorById(String? id) {
    if (id == null) return '(sem leitor)';
    try {
      return _leitores.firstWhere((l) => l.id == id).nome;
    } catch (_) {
      return 'Leitor';
    }
  }

  // Constrói os itens do dropdown de leitor (mantendo seleção em edição)
  List<DropdownMenuItem<String>> _buildLeitorItems() {
    final items = _leitoresFiltrados
        .map((l) => DropdownMenuItem<String>(
              value: l.id,
              child: Text(l.nome),
            ))
        .toList();

    // Se estamos a editar e o leitor atual não está nos filtrados,
    // injeta um item sintético com o próprio ID para manter a seleção.
    if (_leitorId != null &&
        _leitoresFiltrados.every((l) => l.id != _leitorId)) {
      items.insert(
        0,
        DropdownMenuItem<String>(
          value: _leitorId,
          child: Text('${_nomeLeitorById(_leitorId)} (fora da escala)'),
        ),
      );
    }
    return items;
  }

  // Salvar (criar ou atualizar)
  Future<void> _salvarPresenca() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final presenca = PresencaModel(
      id: widget.presenca?.id ?? '',
      escalaId: _escalaId!,
      leitorId: _leitorId!,
      data: _data,
      presenteMissa: _presenteMissa,
      presenteEnsaio: _presenteEnsaio,
      diccao: _diccao,
      colocacaoVoz: _colocacaoVoz,
      sinaisPontuacao: _sinaisPontuacao,
      ritmo: _ritmo,
      observacao: _observacao,
    );

    try {
      if (widget.presenca != null && (widget.presenca!.id.isNotEmpty)) {
        await _firestoreService.atualizarPresenca(presenca);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Presença atualizada!')),
        );
      } else {
        await _firestoreService.registrarPresenca(presenca);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Presença registrada!')),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao salvar presença: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.presenca != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Editar Presença' : 'Registrar Presença')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seleção de Escala Litúrgica
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Selecione a Escala Litúrgica'),
                  value: _escalaId,
                  onChanged: (value) {
                    setState(() {
                      _escalaId = value;
                      _leitorId = null; // ao mudar a escala, força nova escolha do leitor

                      // Sincroniza a data com a escala escolhida
                      final escalaSelecionada = _escalasLiturgicas.firstWhere(
                        (escala) => escala.id == _escalaId,
                        orElse: () => EscalaLiturgica(
                          id: '',
                          domingo: '',
                          data: DateFormat('yyyy-MM-dd').format(_data),
                          introdutorId: '',
                          primeiraLeituraLLId: '',
                          primeiraLeituraPTId: '',
                          segundaLeituraLLId: '',
                          segundaLeituraPTId: '',
                          evangelhoId: '',
                        ),
                      );

                      if (escalaSelecionada.data.isNotEmpty) {
                        _data = DateTime.tryParse(escalaSelecionada.data) ?? _data;
                        _updateDataCtrl();
                      }

                      _loadLeitores();
                    });
                  },
                  items: _escalasLiturgicas.map((escala) {
                    return DropdownMenuItem<String>(
                      value: escala.id,
                      child: Text(escala.domingo),
                    );
                  }).toList(),
                  validator: (value) => value == null ? 'Selecione uma escala' : null,
                ),

                // Data (readOnly)
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Data'),
                  controller: _dataCtrl,
                  readOnly: true,
                  validator: (value) => (value == null || value.isEmpty) ? 'Campo obrigatório' : null,
                ),

                // Seleção de Leitor
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Selecione o Leitor'),
                  value: _leitorId,
                  items: _buildLeitorItems(),
                  onChanged: (value) => setState(() => _leitorId = value),
                  validator: (value) => value == null ? 'Selecione um leitor' : null,
                ),

                // Presenças
                SwitchListTile(
                  title: const Text('Presente no Ensaio'),
                  value: _presenteEnsaio,
                  onChanged: (value) => setState(() => _presenteEnsaio = value),
                ),
                SwitchListTile(
                  title: const Text('Presente na Missa'),
                  value: _presenteMissa,
                  onChanged: (value) => setState(() => _presenteMissa = value),
                ),

                if (_presenteMissa) ...[
                  const SizedBox(height: 8),
                  const Text('Avaliação (0 a 10):', style: TextStyle(fontWeight: FontWeight.bold)),

                  const SizedBox(height: 8),
                  const Text('Dicção'),
                  Slider(
                    value: _diccao,
                    min: 0, max: 10, divisions: 10,
                    label: _diccao.toStringAsFixed(0),
                    onChanged: (v) => setState(() => _diccao = v),
                  ),

                  const Text('Colocação de Voz'),
                  Slider(
                    value: _colocacaoVoz,
                    min: 0, max: 10, divisions: 10,
                    label: _colocacaoVoz.toStringAsFixed(0),
                    onChanged: (v) => setState(() => _colocacaoVoz = v),
                  ),

                  const Text('Sinais de Pontuação'),
                  Slider(
                    value: _sinaisPontuacao,
                    min: 0, max: 10, divisions: 10,
                    label: _sinaisPontuacao.toStringAsFixed(0),
                    onChanged: (v) => setState(() => _sinaisPontuacao = v),
                  ),

                  const Text('Ritmo'),
                  Slider(
                    value: _ritmo,
                    min: 0, max: 10, divisions: 10,
                    label: _ritmo.toStringAsFixed(0),
                    onChanged: (v) => setState(() => _ritmo = v),
                  ),
                ],

                TextFormField(
                  decoration: const InputDecoration(labelText: 'Observação'),
                  maxLines: 3,
                  initialValue: _observacao,
                  onSaved: (v) => _observacao = v ?? '',
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _salvarPresenca,
                    icon: const Icon(Icons.save),
                    label: Text(isEdit ? 'Guardar alterações' : 'Salvar'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
