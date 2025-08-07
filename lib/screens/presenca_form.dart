import 'package:flutter/material.dart';
import 'package:gestao_leitores/models/escala_liturgica.dart';
import 'package:gestao_leitores/models/leitor.dart';
import 'package:gestao_leitores/models/presenca_model.dart';
import 'package:gestao_leitores/services/firestore_service.dart';

class PresencaForm extends StatefulWidget { 
  @override
  _PresencaFormState createState() => _PresencaFormState();
}

class _PresencaFormState extends State<PresencaForm> {   
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  String? _escalaId;
  String? _leitorId;
  DateTime _data = DateTime.now(); // Inicializa com a data atual
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

  @override
  void initState() {
    super.initState();
    _loadEscalasLiturgicas();
  }

  // Carregar as escalas litúrgicas do Firestore
  void _loadEscalasLiturgicas() {
    _firestoreService.getEscalasLiturgicas().listen((escalas) {
      setState(() {
        _escalasLiturgicas = escalas;
      });
    });
  }

  // Carregar os leitores do Firestore, e filtrar com base na escala selecionada
  void _loadLeitores() {
    _firestoreService.getLeitores().listen((leitores) {
      setState(() {
        _leitores = leitores;

        // Filtrar os leitores com base na escala selecionada
        if (_escalaId != null) {
          final escalaSelecionada = _escalasLiturgicas.firstWhere((escala) => escala.id == _escalaId);
          _leitoresFiltrados = _leitores.where((leitor) {
            // Verificando se o leitor está relacionado com algum campo da escala
            return [escalaSelecionada.introdutorId, escalaSelecionada.primeiraLeituraLLId, escalaSelecionada.primeiraLeituraPTId, 
                    escalaSelecionada.segundaLeituraLLId, escalaSelecionada.segundaLeituraPTId, escalaSelecionada.evangelhoId]
                    .contains(leitor.id);
          }).toList();
        }
      });
    });
  }

  // Salvar a presença
  void _salvarPresenca() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final presenca = PresencaModel(
        id: '', // ID será gerado automaticamente pelo Firestore
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

      // Salvar no Firestore
      _firestoreService.registrarPresenca(presenca);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Presença registrada!')));
      Navigator.pop(context); // Fechar o formulário após salvar
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registrar Presença')),
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
                  decoration: InputDecoration(labelText: 'Selecione a Escala Litúrgica'),
                  value: _escalaId,
                  onChanged: (value) {
                    setState(() {
                      _escalaId = value;
                      _leitorId = null; // Limpar o campo do leitor quando o domingo for alterado

                      // Encontrar o domingo correspondente à escala selecionada
                      final escalaSelecionada = _escalasLiturgicas.firstWhere((escala) => escala.id == _escalaId);
                      // Atualizar a data com a data do domingo selecionado
                      _data = DateTime.parse(escalaSelecionada.data); // Converter string para DateTime

                      // Carregar leitores filtrados para a escala selecionada
                      _loadLeitores();
                    });
                  },
                  items: _escalasLiturgicas.map((escala) {
                    return DropdownMenuItem<String>(
                      value: escala.id,
                      child: Text(escala.domingo),
                    );
                  }).toList(),
                  validator: (value) {
                    if (value == null) {
                      return 'Selecione uma escala';
                    }
                    return null;
                  },
                ),

                // Campo de data - Exibido mas não editável
                TextFormField(
                  decoration: InputDecoration(labelText: 'Data'),
                  controller: TextEditingController(text: _data.toLocal().toString().split(' ')[0]),
                  readOnly: true,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Campo obrigatório';
                    }
                    return null;
                  },
                ),

                // Seleção de Leitor
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Selecione o Leitor'),
                  value: _leitorId,
                  onChanged: (value) {
                    setState(() {
                      _leitorId = value;
                    });
                  },
                  items: _leitoresFiltrados.map((leitor) {
                    return DropdownMenuItem<String>(
                      value: leitor.id,
                      child: Text(leitor.nome),
                    );
                  }).toList(),
                  validator: (value) {
                    if (value == null) {
                      return 'Selecione um leitor';
                    }
                    return null;
                  },
                ),

                // Campo de presença
                SwitchListTile(
                  title: Text('Presente no Ensaio'),
                  value: _presenteEnsaio,
                  onChanged: (value) => setState(() => _presenteEnsaio = value),
                ),
                SwitchListTile(
                  title: Text('Presente na Missa'),
                  value: _presenteMissa,
                  onChanged: (value) => setState(() => _presenteMissa = value),
                ),

                // Avaliação de dicção
                if (_presenteMissa) ...[
                  Text('Avaliação (0 a 10):'),
                  Text('Dicção'),
                  Slider(
                    value: _diccao,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: _diccao.toString(),
                    onChanged: (value) => setState(() => _diccao = value),
                  ),

                  // Avaliação de colocação de voz
                  Text('Colocação de Voz'),
                  Slider(
                    value: _colocacaoVoz,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: _colocacaoVoz.toString(),
                    onChanged: (value) => setState(() => _colocacaoVoz = value),
                  ),

                  // Avaliação de sinais de pontuação
                  Text('Sinais de Pontuação'),
                  Slider(
                    value: _sinaisPontuacao,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: _sinaisPontuacao.toString(),
                    onChanged: (value) => setState(() => _sinaisPontuacao = value),
                  ),

                  // Avaliação de ritmo
                  Text('Ritmo'),
                  Slider(
                    value: _ritmo,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: _ritmo.toString(),
                    onChanged: (value) => setState(() => _ritmo = value),
                  ),
                ],

                // Campo de observação
                TextFormField(
                  decoration: InputDecoration(labelText: 'Observação'),
                  maxLines: 3,
                  onSaved: (value) => _observacao = value ?? '',
                ),

                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _salvarPresenca,
                  child: Text('Salvar'),
                ),
                SizedBox(height: 20), 
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
