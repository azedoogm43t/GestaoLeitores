import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/leitor.dart';
import '../models/escala_liturgica.dart';
import '../services/firestore_service.dart';

class EscalaForm extends StatefulWidget {
   final EscalaLiturgica? escala;
  const EscalaForm({Key? key, this.escala}) : super(key: key);

  @override
  State<EscalaForm> createState() => _EscalaFormState();
}

class _EscalaFormState extends State<EscalaForm> {
  final _formKey = GlobalKey<FormState>();
  final _service = FirestoreService();
  final _domingoController = TextEditingController();
  final DateFormat _formatter = DateFormat('yyyy-MM-dd');
  DateTime _dataSelecionada = DateTime.now();

  Leitor? _introdutor;
  Leitor? _primeiraLL;
  Leitor? _primeiraPT;
  Leitor? _segundaLL;
  Leitor? _segundaPT;
  Leitor? _evangelho;

  @override
void initState() {
  super.initState();

  if (widget.escala != null) {
    final escala = widget.escala!;
    _domingoController.text = escala.domingo;
    _dataSelecionada = DateTime.parse(escala.data);

    // Carregar leitores por ID
    _carregarLeitores(escala);
  }
}

void _carregarLeitores(EscalaLiturgica escala) async {
  final introdutor = await _service.getLeitorById(escala.introdutorId);
  final primeiraLL = await _service.getLeitorById(escala.primeiraLeituraLLId);
  final primeiraPT = await _service.getLeitorById(escala.primeiraLeituraPTId);
  final segundaLL = await _service.getLeitorById(escala.segundaLeituraLLId);
  final segundaPT = await _service.getLeitorById(escala.segundaLeituraPTId);
  final evangelho = await _service.getLeitorById(escala.evangelhoId);

  if (!mounted) return; // garantir que o widget ainda está ativo

  setState(() {
    _introdutor = introdutor;
    _primeiraLL = primeiraLL;
    _primeiraPT = primeiraPT;
    _segundaLL = segundaLL;
    _segundaPT = segundaPT;
    _evangelho = evangelho;
  });
}


  List<Leitor> _filtrar(List<Leitor> todos, String idioma) =>
      todos.where((l) => l.idiomas.contains(idioma)).toList();

  Future<void> _pickDate() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (data != null) setState(() => _dataSelecionada = data);
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    if ([
      _introdutor,
      _primeiraLL,
      _primeiraPT,
      _segundaLL,
      _segundaPT,
      _evangelho,
    ].contains(null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione todos os leitores!')),
      );
      return;
    }

    final escala = EscalaLiturgica(
      id: '',
      domingo: _domingoController.text.trim(),
      data: _formatter.format(_dataSelecionada),
      introdutorId: _introdutor!.id,
      primeiraLeituraLLId: _primeiraLL!.id,
      primeiraLeituraPTId: _primeiraPT!.id,
      segundaLeituraLLId: _segundaLL!.id,
      segundaLeituraPTId: _segundaPT!.id,
      evangelhoId: _evangelho!.id,
    );

    _service.addEscalaLiturgica(escala);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _domingoController.dispose();
    super.dispose();
  }

  DropdownButtonFormField<Leitor> _buildDropdown({
  required String hint,
  required Leitor? value,
  required List<Leitor> lista,
  required ValueChanged<Leitor?> onChanged,
}) {
  return DropdownButtonFormField<Leitor>(
    value: value,
    decoration: InputDecoration(
      labelText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.always, // fixo sempre na borda
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Escala Litúrgica'),
        centerTitle: true,
        backgroundColor: Colors.teal.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: StreamBuilder<List<Leitor>>(
            stream: _service.getLeitores(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final todos = snapshot.data!;
              final ll = _filtrar(todos, 'Língua Local');
              final pt = _filtrar(todos, 'Português');

               // Filtra só os casados para Evangelho
            final evangelhoCasados = ll.where((l) => l.estadoCivil.contains('Casado canonicamente')).toList();

              return ListView(
                children: [
                  TextFormField(
                    controller: _domingoController,
                    decoration: const InputDecoration(
                      labelText: 'Domingo / Título',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 16),

                  _buildDropdown(
                    hint: 'Introdutor',
                    value: _introdutor,
                    lista: todos,
                    onChanged: (l) => setState(() => _introdutor = l),
                  ),
                  const SizedBox(height: 16),

                  _buildDropdown(
                    hint: '1ª Leitura (Língua Local)',
                    value: _primeiraLL,
                    lista: ll,
                    onChanged: (l) => setState(() => _primeiraLL = l),
                  ),
                  const SizedBox(height: 16),

                  _buildDropdown(
                    hint: '1ª Leitura (Português)',
                    value: _primeiraPT,
                    lista: pt,
                    onChanged: (l) => setState(() => _primeiraPT = l),
                  ),
                  const SizedBox(height: 16),

                  _buildDropdown(
                    hint: '2ª Leitura (Língua Local)',
                    value: _segundaLL,
                    lista: ll,
                    onChanged: (l) => setState(() => _segundaLL = l),
                  ),
                  const SizedBox(height: 16),

                  _buildDropdown(
                    hint: '2ª Leitura (Português)',
                    value: _segundaPT,
                    lista: pt,
                    onChanged: (l) => setState(() => _segundaPT = l),
                  ),
                  const SizedBox(height: 16),

                  _buildDropdown(
                    hint: 'Evangelho (Língua Local)',
                    value: _evangelho,
                    lista: evangelhoCasados,
                    onChanged: (l) => setState(() => _evangelho = l),
                  ),
                  const SizedBox(height: 24),

                 GestureDetector(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Data da Escala',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        suffixIcon: const Icon(Icons.calendar_today),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      child: Text(
                        _formatter.format(_dataSelecionada),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                   const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _salvar,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text('Salvar Escala', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.teal.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
