import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/leitor.dart';

class LeitorForm extends StatefulWidget {
  final Leitor? leitor;

  const LeitorForm({Key? key, this.leitor}) : super(key: key);

  @override
  _LeitorFormState createState() => _LeitorFormState();
}

class _LeitorFormState extends State<LeitorForm> {
  final _formKey = GlobalKey<FormState>();
  final _service = FirestoreService();

  late TextEditingController _nomeController;
  late TextEditingController _contactoController;
  List<String> _idiomasSelecionados = [];
    List<String> _estadoCivilSelecionado = [];

  final List<String> _idiomasDisponiveis = ['Português', 'Língua Local'];
  final List<String> _estadoCivilDisponivel = ['Solteiro', 'Casado canonicamente'];

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.leitor?.nome ?? '');
    _contactoController = TextEditingController(text: widget.leitor?.contacto ?? '');
    _idiomasSelecionados = widget.leitor?.idiomas.toList() ?? [];
    _estadoCivilSelecionado = widget.leitor?.estadoCivil.toList() ?? [];
  }

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      final leitor = Leitor(
        id: widget.leitor?.id ?? '', // Mantém id para edição, vazio para novo
        nome: _nomeController.text.trim(),
        contacto: _contactoController.text.trim(),
        idiomas: _idiomasSelecionados,
        ativo: widget.leitor?.ativo ?? true,
        estadoCivil: _estadoCivilSelecionado,
      );

      if (widget.leitor == null) {
        _service.addLeitor(leitor);
      } else {
        _service.updateLeitor(leitor);
      }

      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _contactoController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.leitor == null ? 'Novo Leitor' : 'Editar Leitor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: _inputDecoration('Nome'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactoController,
                decoration: _inputDecoration('Contacto'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Informe o contacto' : null,
              ),
              const SizedBox(height: 24),

              const Text(
                'Idiomas:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),

              ..._idiomasDisponiveis.map((idioma) {
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(idioma),
                  value: _idiomasSelecionados.contains(idioma),
                  onChanged: (bool? selected) {
                    setState(() {
                      if (selected == true) {
                        _idiomasSelecionados.add(idioma);
                      } else {
                        _idiomasSelecionados.remove(idioma);
                      }
                    });
                  },
                );
              }).toList(),
              const SizedBox(height: 32),
              const Text(
                'Estado Civil:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),

             ..._estadoCivilDisponivel.map((estadoCivil) {
                  return RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(estadoCivil),
                    value: estadoCivil,
                    groupValue: _estadoCivilSelecionado.isNotEmpty ? _estadoCivilSelecionado.first : null,
                    onChanged: (String? selected) {
                      setState(() {
                        if (selected != null) {
                          _estadoCivilSelecionado = [selected]; // mantém só o selecionado
                        }
                      });
                    },
                  );
                }).toList(),
              const SizedBox(height: 32),

              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _salvar,
                  icon: const Icon(Icons.save, color: Colors.teal),
                  label: const Text(
                    'Salvar',
                    style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
