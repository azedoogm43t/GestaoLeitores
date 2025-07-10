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
  final _formKey7 = GlobalKey<FormState>();
  final _formKey9 = GlobalKey<FormState>();
  final _service = FirestoreService();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  DateTime _dataSelecionada = DateTime.now();

  // Missa das 7h
  String _descricao7 = '';
  Leitor? _introdutor7,
      _leitura1LL7,
      _leitura1PT7,
      _leitura2LL7,
      _leitura2PT7,
      _evangelho7;

  // Missa das 9h
  String _descricao9 = '';
  Leitor? _introdutor9, _leitura1PT9, _leitura2PT9;

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (data != null) {
      setState(() => _dataSelecionada = data);
    }
  }

  List<Leitor> _filtrar(List<Leitor> leitores, String idioma) {
    return leitores.where((l) => l.idiomas.contains(idioma)).toList();
  }

  Widget _buildDropdown(String label, Leitor? valor, List<Leitor> lista,
      void Function(Leitor?) onChanged) {
    return DropdownButtonFormField<Leitor>(
      value: valor,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: lista.map((leitor) {
        return DropdownMenuItem(
          value: leitor,
          child: Text(leitor.nome),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Obrigatório' : null,
    );
  }

  void _salvar7(List<Leitor> leitoresPT, List<Leitor> leitoresLL) {
    if (_formKey7.currentState!.validate() &&
        [
          _introdutor7,
          _leitura1LL7,
          _leitura1PT7,
          _leitura2LL7,
          _leitura2PT7,
          _evangelho7
        ].every((l) => l != null)) {
      final escala = EscalaLiturgica(
        id: '',
        data: _dateFormat.format(_dataSelecionada),
        domingo: _descricao7,
        introdutorId: _introdutor7!.id,
        primeiraLeituraLLId: _leitura1LL7!.id,
        primeiraLeituraPTId: _leitura1PT7!.id,
        segundaLeituraLLId: _leitura2LL7!.id,
        segundaLeituraPTId: _leitura2PT7!.id,
        evangelhoId: _evangelho7!.id,
      );
      _service.addEscalaLiturgica(escala);
      Navigator.pop(context);
    }
  }

  void _salvar9(List<Leitor> leitoresPT) {
    if (_formKey9.currentState!.validate() &&
        [_introdutor9, _leitura1PT9, _leitura2PT9].every((l) => l != null)) {
      final escala = EscalaLiturgica(
        id: '',
        data: _dateFormat.format(_dataSelecionada),
        domingo: _descricao9,
        introdutorId: _introdutor9!.id,
        primeiraLeituraLLId: '',
        primeiraLeituraPTId: _leitura1PT9!.id,
        segundaLeituraLLId: '',
        segundaLeituraPTId: _leitura2PT9!.id,
        evangelhoId: '', // Missa das 9h não tem evangelho
      );
      _service.addEscalaLiturgica(escala);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Nova Escala Litúrgica"),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Missa das 7h'),
              Tab(text: 'Missa das 9h'),
            ],
          ),
        ),
        body: StreamBuilder<List<Leitor>>(
          stream: _service.getLeitores(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final leitores = snapshot.data!;
            final leitoresPT = _filtrar(leitores, 'Português');
            final leitoresLL = _filtrar(leitores, 'Língua Local');

            return TabBarView(
              children: [
                // Missa das 7h
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey7,
                    child: ListView(
                      children: [
                        _buildDataSelector(),
                        const SizedBox(height: 8),
                        _buildDescricao((v) => _descricao7 = v),
                        const SizedBox(height: 16),
                        _buildDropdown("Introdutor", _introdutor7, leitores,
                            (v) => setState(() => _introdutor7 = v)),
                        const SizedBox(height: 16),
                        _buildDropdown(
                            "1ª Leitura (Língua Local)",
                            _leitura1LL7,
                            leitoresLL,
                            (v) => setState(() => _leitura1LL7 = v)),
                        const SizedBox(height: 16),
                        _buildDropdown(
                            "1ª Leitura (Português)",
                            _leitura1PT7,
                            leitoresPT,
                            (v) => setState(() => _leitura1PT7 = v)),
                        const SizedBox(height: 16),
                        _buildDropdown(
                            "2ª Leitura (Língua Local)",
                            _leitura2LL7,
                            leitoresLL,
                            (v) => setState(() => _leitura2LL7 = v)),
                        const SizedBox(height: 16),
                        _buildDropdown(
                            "2ª Leitura (Português)",
                            _leitura2PT7,
                            leitoresPT,
                            (v) => setState(() => _leitura2PT7 = v)),
                        const SizedBox(height: 16),
                        _buildDropdown("Evangelho", _evangelho7, leitoresLL,
                            (v) => setState(() => _evangelho7 = v)),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => _salvar7(leitoresPT, leitoresLL),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal, // ou Colors.green
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Salvar Escala 7h",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Missa das 9h
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey9,
                    child: ListView(
                      children: [
                        _buildDataSelector(),
                        const SizedBox(height: 8),
                        _buildDescricao((v) => _descricao9 = v),
                        const SizedBox(height: 16),
                        _buildDropdown("Introdutor", _introdutor9, leitoresPT,
                            (v) => setState(() => _introdutor9 = v)),
                        _buildDropdown(
                            "1ª Leitura (Português)",
                            _leitura1PT9,
                            leitoresPT,
                            (v) => setState(() => _leitura1PT9 = v)),
                        _buildDropdown(
                            "2ª Leitura (Português)",
                            _leitura2PT9,
                            leitoresPT,
                            (v) => setState(() => _leitura2PT9 = v)),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => _salvar9(leitoresPT),
                          child: const Text("Salvar Escala 9h"),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDataSelector() {
    return Row(
      children: [
        Expanded(child: Text('Data: ${_dateFormat.format(_dataSelecionada)}')),
        TextButton(
            onPressed: _selecionarData, child: const Text('Selecionar Data')),
      ],
    );
  }

  Widget _buildDescricao(ValueChanged<String> onChanged) {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Descrição do Domingo',
        border: OutlineInputBorder(),
      ),
      onChanged: onChanged,
      validator: (v) => v == null || v.isEmpty ? 'Informe a descrição' : null,
    );
  }
}
