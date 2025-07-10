import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gestao_leitores/models/usuarios.dart';
import 'package:intl/intl.dart';
import '../models/leitor.dart';
import '../models/escala_liturgica.dart';
import '../services/firestore_service.dart';

class EscalaForm extends StatefulWidget {
  final EscalaLiturgica? escala;
  final Usuario? usuario;

  const EscalaForm({Key? key, this.escala, this.usuario}) : super(key: key);

  @override
  State<EscalaForm> createState() => _EscalaFormState();
}

class _EscalaFormState extends State<EscalaForm> with TickerProviderStateMixin {
  final _formKey7 = GlobalKey<FormState>();
  final _formKey9 = GlobalKey<FormState>();
  final _domingoController7 = TextEditingController();
  final _domingoController9 = TextEditingController();
  late TabController _tabController;
  int _initialTabIndex = 0;
  EscalaLiturgica? _escalaExistente;

  final _service = FirestoreService();
  final DateFormat _formatter = DateFormat('yyyy-MM-dd');

  DateTime _dataSelecionada7 = DateTime.now();
  DateTime _dataSelecionada9 = DateTime.now();

  // Missa das 7h (todos os leitores)
  Leitor? _introdutor7;
  Leitor? _primeiraLL7;
  Leitor? _primeiraPT7;
  Leitor? _segundaLL7;
  Leitor? _segundaPT7;
  Leitor? _evangelho7;

  // Missa das 9h (apenas leitores PT para introdutor, 1ª e 2ª leitura)
  Leitor? _introdutor9;
  Leitor? _primeiraPT9;
  Leitor? _segundaPT9;

  @override
  void initState() {
    super.initState();

    final escala = widget.escala;

    // Detectar tipo da escala
    final bool is7h = escala != null &&
        (escala.primeiraLeituraLLId.isNotEmpty ||
            escala.evangelhoId.isNotEmpty);
    _initialTabIndex = is7h ? 0 : 1;

    // Inicializar controller com índice correto
    _tabController =
        TabController(length: 2, vsync: this, initialIndex: _initialTabIndex);

    if (escala != null) {
      if (is7h) {
        // Preencher apenas os campos da Missa das 7h
        _domingoController7.text = escala.domingo;
        _dataSelecionada7 = DateTime.parse(escala.data);
      } else {
        // Preencher apenas os campos da Missa das 9h
        _domingoController9.text = escala.domingo;
        _dataSelecionada9 = DateTime.parse(escala.data);
      }

      _carregarLeitores(escala);
    }
  }

  void _carregarLeitores(EscalaLiturgica escala) async {
    final introdutor = await _service.getLeitorById(escala.introdutorId);
    final primeiraLL = escala.primeiraLeituraLLId.isNotEmpty
        ? await _service.getLeitorById(escala.primeiraLeituraLLId)
        : null;
    final primeiraPT = await _service.getLeitorById(escala.primeiraLeituraPTId);
    final segundaLL = escala.segundaLeituraLLId.isNotEmpty
        ? await _service.getLeitorById(escala.segundaLeituraLLId)
        : null;
    final segundaPT = await _service.getLeitorById(escala.segundaLeituraPTId);
    final evangelho = escala.evangelhoId.isNotEmpty
        ? await _service.getLeitorById(escala.evangelhoId)
        : null;

    if (!mounted) return;

    setState(() {
      if (_initialTabIndex == 0) {
        // Missa das 7h
        _introdutor7 = introdutor;
        _primeiraLL7 = primeiraLL;
        _primeiraPT7 = primeiraPT;
        _segundaLL7 = segundaLL;
        _segundaPT7 = segundaPT;
        _evangelho7 = evangelho;
      } else {
        // Missa das 9h
        _introdutor9 = introdutor;
        _primeiraPT9 = primeiraPT;
        _segundaPT9 = segundaPT;
      }
    });
  }

  List<Leitor> _filtrar(List<Leitor> todos, String idioma) =>
      todos.where((l) => l.idiomas.contains(idioma)).toList();

  List<Leitor> _filtrarCasados(List<Leitor> leitores) => leitores
      .where((l) => l.estadoCivil.contains('Casado canonicamente'))
      .toList();

  Future<void> _pickDate7() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada7,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (data != null) setState(() => _dataSelecionada7 = data);
  }

  Future<void> _pickDate9() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada9,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (data != null) setState(() => _dataSelecionada9 = data);
  }

  void _salvar7() {
    if (!_formKey7.currentState!.validate()) return;

    if ([
      _introdutor7,
      _primeiraLL7,
      _primeiraPT7,
      _segundaLL7,
      _segundaPT7,
      _evangelho7,
    ].contains(null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecione todos os leitores na Missa das 7h!')),
      );
      return;
    }

    final escala = EscalaLiturgica(
      id: widget.escala?.id ??
          '', // <-- aqui: usa id existente ou vazio se novo
      domingo: _domingoController7.text.trim(),
      data: _formatter.format(_dataSelecionada7),
      introdutorId: _introdutor7!.id,
      primeiraLeituraLLId: _primeiraLL7!.id,
      primeiraLeituraPTId: _primeiraPT7!.id,
      segundaLeituraLLId: _segundaLL7!.id,
      segundaLeituraPTId: _segundaPT7!.id,
      evangelhoId: _evangelho7!.id,
    );

    try {
      if (widget.escala == null) {
        _service.addEscalaLiturgica(escala);
        _mostrarToast('Escala cadastrada com sucesso!');
      } else {
        _service.updateEscalaLiturgica(escala);
        _mostrarToast('Escala atualizada com sucesso!');
      }

      Future.delayed(const Duration(seconds: 3));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _mostrarToast('Erro ao salvar escala', isErro: true);
    }
  }

  void _salvar9() {
    if (!_formKey9.currentState!.validate()) return;

    if ([_introdutor9, _primeiraPT9, _segundaPT9].contains(null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecione todos os leitores na Missa das 9h!')),
      );
      return;
    }

    final escala = EscalaLiturgica(
      id: widget.escala?.id ?? '', // <-- idem, usa id existente se editar
      domingo: _domingoController9.text.trim(),
      data: _formatter.format(_dataSelecionada9),
      introdutorId: _introdutor9!.id,
      primeiraLeituraLLId: '',
      primeiraLeituraPTId: _primeiraPT9!.id,
      segundaLeituraLLId: '',
      segundaLeituraPTId: _segundaPT9!.id,
      evangelhoId: '',
    );

    try {
      if (widget.escala == null) {
        _service.addEscalaLiturgica(escala);
        _mostrarToast('Escala cadastrada com sucesso!');
      } else {
        _service.updateEscalaLiturgica(escala);
        _mostrarToast('Escala atualizada com sucesso!');
      }

      Future.delayed(const Duration(seconds: 3));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _mostrarToast('Erro ao salvar escala', isErro: true);
    }
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
        floatingLabelBehavior: FloatingLabelBehavior.always,
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

  Widget _buildDataSelector(DateTime dataSelecionada, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Data da Escala',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: const Icon(Icons.calendar_today),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        child: Text(
          _formatter.format(dataSelecionada),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  void _mostrarToast(String mensagem, {bool isErro = false}) {
    Fluttertoast.showToast(
      msg: mensagem,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor:
          isErro ? Colors.redAccent : Color.fromARGB(255, 14, 116, 56),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  void dispose() {
    _domingoController7.dispose();
    _domingoController9.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nova Escala Litúrgica'),
          centerTitle: true,
          backgroundColor: Colors.teal.shade700,
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                  child: Text('Missa das 7h',
                      style: TextStyle(color: Colors.white))),
              Tab(
                  child: Text('Missa das 9h',
                      style: TextStyle(color: Colors.white))),
            ],
            indicatorColor: Colors.white,
          ),
        ),
        body: StreamBuilder<List<Leitor>>(
          stream: _service.getLeitores(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());

            final todos = snapshot.data!;
            final ll = _filtrar(todos, 'Língua Local');
            final pt = _filtrar(todos, 'Português');
            final evangelhoCasados = _filtrarCasados(ll);

            return TabBarView(
              controller: _tabController,
              children: [
                // Missa das 7h (todos leitores)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey7,
                    child: ListView(
                      children: [
                        TextFormField(
                          controller: _domingoController7,
                          decoration: const InputDecoration(
                            labelText: 'Domingo / Título',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Obrigatório'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                            hint: 'Introdutor',
                            value: _introdutor7,
                            lista: todos,
                            onChanged: (l) => setState(() => _introdutor7 = l)),
                        const SizedBox(height: 16),
                        _buildDropdown(
                            hint: '1ª Leitura (Língua Local)',
                            value: _primeiraLL7,
                            lista: ll,
                            onChanged: (l) => setState(() => _primeiraLL7 = l)),
                        const SizedBox(height: 16),
                        _buildDropdown(
                            hint: '1ª Leitura (Português)',
                            value: _primeiraPT7,
                            lista: pt,
                            onChanged: (l) => setState(() => _primeiraPT7 = l)),
                        const SizedBox(height: 16),
                        _buildDropdown(
                            hint: '2ª Leitura (Língua Local)',
                            value: _segundaLL7,
                            lista: ll,
                            onChanged: (l) => setState(() => _segundaLL7 = l)),
                        const SizedBox(height: 16),
                        _buildDropdown(
                            hint: '2ª Leitura (Português)',
                            value: _segundaPT7,
                            lista: pt,
                            onChanged: (l) => setState(() => _segundaPT7 = l)),
                        const SizedBox(height: 16),
                        _buildDropdown(
                            hint: 'Evangelho (Língua Local)',
                            value: _evangelho7,
                            lista: evangelhoCasados,
                            onChanged: (l) => setState(() => _evangelho7 = l)),
                        const SizedBox(height: 24),
                        _buildDataSelector(_dataSelecionada7, _pickDate7),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _salvar7,
                            icon: const Icon(Icons.save, color: Colors.white),
                            label: const Text('Salvar Escala',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.teal.shade700,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Missa das 9h (apenas leitores PT para introdutor e leituras)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey9,
                    child: ListView(
                      children: [
                        TextFormField(
                          controller: _domingoController9,
                          decoration: const InputDecoration(
                            labelText: 'Domingo / Título',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Obrigatório'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                            hint: 'Introdutor',
                            value: _introdutor9,
                            lista: pt,
                            onChanged: (l) => setState(() => _introdutor9 = l)),
                        const SizedBox(height: 16),
                        _buildDropdown(
                            hint: '1ª Leitura (Português)',
                            value: _primeiraPT9,
                            lista: pt,
                            onChanged: (l) => setState(() => _primeiraPT9 = l)),
                        const SizedBox(height: 16),
                        _buildDropdown(
                            hint: '2ª Leitura (Português)',
                            value: _segundaPT9,
                            lista: pt,
                            onChanged: (l) => setState(() => _segundaPT9 = l)),
                        const SizedBox(height: 24),
                        _buildDataSelector(_dataSelecionada9, _pickDate9),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _salvar9,
                            icon: const Icon(Icons.save, color: Colors.white),
                            label: const Text('Salvar Escala',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.teal.shade700,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
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
}
