import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/escala_liturgica.dart';
import '../models/leitor.dart';
import '../services/firestore_service.dart';

class EscalaLiturgicaForm extends StatefulWidget {
  const EscalaLiturgicaForm({super.key});

  @override
  State<EscalaLiturgicaForm> createState() => _EscalaLiturgicaFormState();
}

class _EscalaLiturgicaFormState extends State<EscalaLiturgicaForm> {
  final _formKey = GlobalKey<FormState>();
  final _service = FirestoreService();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  DateTime _dataSelecionada = DateTime.now();
  String _domingoDescricao = '';

  Leitor? _introdutor;
  Leitor? _leitura1Local;
  Leitor? _leitura1Port;
  Leitor? _leitura2Local;
  Leitor? _leitura2Port;
  Leitor? _evangelho;



  void _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (data != null) setState(() => _dataSelecionada = data);
  }

  void _salvar() {
    if (_formKey.currentState!.validate() &&
        _introdutor != null &&
        _leitura1Local != null &&
        _leitura1Port != null &&
        _leitura2Local != null &&
        _leitura2Local != null &&
        _evangelho != null) {
      final escala = EscalaLiturgica(
        id: '',
        data: _dateFormat.format(_dataSelecionada),
        domingo: _domingoDescricao,
        introdutorId: _introdutor!.id,
        primeiraLeituraLLId: _leitura1Local!.id,
        primeiraLeituraPTId: _leitura1Port!.id,
        segundaLeituraLLId: _leitura2Local!.id,
        segundaLeituraPTId: _leitura2Port!.id,
        evangelhoId: _evangelho!.id,
        
      );
      _service.addEscalaLiturgica(escala);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, preencha todos os campos corretamente')),
      );
    }
  }

   Widget _buildLeitorDropdown(String label, Leitor? selected, Function(Leitor?) onChanged, List<Leitor> leitores) {
    return DropdownButtonFormField<Leitor>(
      value: selected,
      hint: Text(label),
      items: leitores.map((leitor) {
        return DropdownMenuItem(
          value: leitor,
          child: Text(leitor.nome),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Escolha o leitor para $label' : null,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nova Escala Litúrgica')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: StreamBuilder<List<Leitor>>(
          stream: _service.getLeitores(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
            final leitores = snapshot.data!;

            return Form(
              key: _formKey,
              child: ListView(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Data: ${_dateFormat.format(_dataSelecionada)}'),
                      ),
                      TextButton(
                        onPressed: _selecionarData,
                        child: Text('Selecionar'),
                      ),
                    ],
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Descrição do Domingo'),
                    onChanged: (v) => _domingoDescricao = v,
                    validator: (v) => v == null || v.isEmpty ? 'Informe a descrição' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildLeitorDropdown('Introdutor', _introdutor, (v) => setState(() => _introdutor = v), leitores),
                  _buildLeitorDropdown('1ª Leitura (Língua local)', _leitura1Local, (v) => setState(() => _leitura1Local = v), leitores),
                  _buildLeitorDropdown('1ª Leitura (Português)', _leitura1Port, (v) => setState(() => _leitura1Port = v), leitores),
                  _buildLeitorDropdown('2ª Leitura (Língua local)', _leitura2Local, (v) => setState(() => _leitura2Local = v), leitores),
                  _buildLeitorDropdown('2ª Leitura (Português)', _leitura2Port, (v) => setState(() => _leitura2Port = v), leitores),
                  _buildLeitorDropdown('Evangelho (Língua Local)', _evangelho, (v) => setState(() => _evangelho = v), leitores),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _salvar,
                    child: Text('Salvar Escala'),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
